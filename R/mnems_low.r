#' @noRd
random_probs <- function(k, data, full = FALSE) {
    probs <- matrix(log2(sample(c(0,1), k*ncol(data),
                                replace = TRUE,
                                prob = c(0.9, 0.1))), k,
                    ncol(data))
    if (full) {
        for (i in seq_len(k)) {
            if (i == 1) { next() }
            infcells <- which(apply(probs, 2, function(x) {
                bad <- FALSE
                if (all(is.infinite(x))) {
                    bad <- TRUE
                }
                return(bad)
            }))
            if (i == k) {
                probs[i, infcells] <- log2(1)
            } else {
                probs[i, infcells] <-
                    log2(sample(c(0,1),
                                length(infcells),
                                replace = TRUE,
                                prob = c(1-1/k, 1/k)))
            }
        }
    }
    while(any(apply(probs, 1, function(x) {
        bad <- FALSE
        if (all(is.infinite(x)) | all(x == 0)) {
            bad <- TRUE
        }
        return(bad)
    }))) {
        probs <- matrix(log2(sample(c(0,1), k*ncol(data),
                                    replace = TRUE,
                                    prob = c(0.9, 0.1))), k,
                        ncol(data))
        if (full) {
            for (i in seq_len(k)) {
                if (i == 1) { next() }
                infcells <- which(apply(probs, 2, function(x) {
                    bad <- FALSE
                    if (all(is.infinite(x))) {
                        bad <- TRUE
                    }
                    return(bad)
                }))
                if (i == k) {
                    probs[i, infcells] <- log2(1)
                } else {
                    probs[i, infcells] <-
                        log2(sample(c(0,1),
                                    length(infcells),
                                    replace = TRUE,
                                    prob = c(1-1/k, 1/k)))
                }
            }
        }
    }
    return(probs)
}
#' @noRd
sortAdj <- function(res, list = FALSE) {
    resmat <- NULL
    for (i in seq_len(length(res))) {
        if (list) {
            resmat <-
                rbind(resmat,
                      as.vector(transitive.closure(res[[i]], mat = TRUE)))
        } else {
            resmat <-
                rbind(resmat,
                      as.vector(transitive.closure(res[[i]]$adj, mat = TRUE)))
        }
    }
    d <- as.matrix(dist(resmat))
    dsum <- apply(d, 1, sum)
    resorder <- which.max(dsum)
    d[resorder, resorder] <- Inf
    for (i in 2:length(dsum)) {
        resorder <- c(resorder, which.min(d[, resorder[length(resorder)]]))
        d[resorder, resorder] <- Inf
    }
    res2 <- list()
    for (i in seq_len(length(res))) {
        res2[[i]] <- res[[resorder[i]]]
    }
    return(list(res = res2, order = resorder))
}
#' @noRd
calcEvopen <- function(res) {
    evopen <- 0
    for (i in seq_len(length(res)-1)) {
        evopen <- evopen + sum(abs(res[[i]]$adj -
                                   res[[(i+1)]]$adj))/length(res[[i]]$adj)
    }
    evopen <- -evopen#/(k-1)
    return(evopen)
}
#' @noRd
modAdj <- function(adj, D) {
    Sgenes <- naturalsort(unique(colnames(D)))
    SgeneN <- getSgeneN(D)
    for (i in seq_len(SgeneN)) {
        colnames(adj) <- rownames(adj) <- gsub(i, Sgenes[i], colnames(adj))
    }
    return(adj)
}
#' @noRd
getOmega <- function(data) {
    
    Sgenes <- unique(unlist(strsplit(colnames(data), "_")))
    
    Omega <- matrix(0, length(Sgenes), ncol(data))
    
    for (i in seq_len(length(Sgenes))) {
        Omega[i, grep(Sgenes[i], colnames(data))] <- 1
    }
    
    rownames(Omega) <- Sgenes
    colnames(Omega) <- colnames(data)

    return(Omega)
}
#' @noRd
initComps <- function(data, k=2, starts=1, verbose = FALSE, meanet = NULL) {
    n <- getSgeneN(data)
    nets <- list()
    for (i in seq_len(starts*k)) {
        tmp <- matrix(sample(c(0,1), replace = TRUE), n, n)
        tmp[lower.tri(tmp)] <- 0
        colnames(tmp) <- rownames(tmp) <- sample(seq_len(n), n)
        tmp <- tmp[order(rownames(tmp)), order(colnames(tmp))]
        nets[[i]] <- tmp
    }
    nets <- sortAdj(nets, list = TRUE)$res
    for (j in seq_len(starts)) {
        init[[j]] <- list()
        for (i in seq_len(k)) {
            do <- (i+starts*(i-1)+j-1-(i-1)*1)
            init[[j]][[i]] <- nets[[do]]
        }
    }
    return(init)
}
#' @noRd
initps <- function(data, ks, k, starts = 3) {
    clusters <- list()
    for (i in seq_len(length(unique(colnames(data))))) {
        d <- dist(t(data[, which(colnames(data) %in% i)]))
        if (length(d) > 1) {
            hc <- hclust(d)
            clusters[[i]] <- cutree(hc, min(ks[i], length(hc$labels)))
        } else {
            clusters[[i]] <- 1
        }
    }
    probscl <- list()
    
    n <- getSgeneN(data)
    
    count <- 0
    llstr <- NULL
    resstr <- NULL
    counter <- 0
    takes <- NULL
    takesdone <- NULL
    while(count < starts & counter < prod(ks)) {
        counter <- counter + 1
        tmp <- matrix(0, k, ncol(data))
        if (ks[1] < k) {
            takes <- as.matrix(sample(seq_len(ks[1]), k, replace = TRUE), k, 1)
        } else {
            takes <- as.matrix(sample(seq_len(ks[1]), k), k, 1)
        }
        for (i in 2:length(unique(colnames(data)))) {
            if (ks[i] < k) {
                takes <- cbind(takes, sample(seq_len(ks[i]), k, replace = TRUE))
            } else {
                takes <- cbind(takes, sample(seq_len(ks[i]), k))
            }
        }
        for (i in seq_len(k)) {
            for (j in seq_len(n)) {
                tmp[i, which(colnames(data) == j)[
                           which(clusters[[j]] == takes[i, j])]] <- 1
            }
        }
        takestmp <- paste(takes, collapse = "")
        if (!(takestmp %in% takesdone)) {
            count <- count + 1
            takesdone <- c(takesdone, takestmp)
            probscl[[count]] <- log2(tmp)
        }
    }
    
    return(probscl)
}
#' @noRd
modData <- function(D) {
    SgeneN <- getSgeneN(D)
    Sgenes <- naturalsort(unique(colnames(D)))
    if (!all(is.numeric(Sgenes))) {
        colnamesD <- numeric(ncol(D))
        for (i in seq_len(SgeneN)) {
            colnamesD[which(colnames(D) %in% Sgenes[i])] <- i
        }
        colnames(D) <- as.numeric(colnamesD)
    }
    rownames(D) <- as.numeric(seq_len(nrow(D)))
    return(D)
}
#' @noRd
#' @importFrom cluster silhouette
learnk <- function(data, kmax = 10, verbose = FALSE) {
    ks <- numeric(length(unique(colnames(data))))
    lab <- list()
    for (i in naturalsort(as.numeric(unique(colnames(data))))) {
        if (verbose) {
            print(i)
        }
        if (sum(colnames(data) %in% i) <= 1) { k <- 1; next() }
        d <- dist(t(data[, which(colnames(data) %in% i)]))
        hc <- hclust(d)
        ks[i] <- 2
        lab[[i]] <- rep(1, sum(colnames(data) %in% i))
        if (length(d) > 1) {
            silavg <- 0
            silavgs <- numeric(length(hc$order)-1)
            clusters <- list()
            for (j in 2:(length(hc$order)-1)) {
                cluster <- cutree(hc, j)
                clusters[[j]] <- cluster
                sil <- silhouette(cluster, d)
                silavgs[j] <- mean(sil[, 3])
                if (verbose) {
                    print(silavgs[j])
                }
                if (silavgs[j] < silavgs[(j-1)]) {
                    break()
                }
                if (silavg < silavgs[j]) {
                    silavg <- silavgs[j]
                    ks[i] <- j
                    lab[[i]] <- cluster
                }
            }
        }
    }
    k <- min(kmax, max(ks))
    return(list(ks = ks, k = k, lab = lab))
}
#' @noRd
getLL <- function(x, logtype = 2, mw = NULL, data = NULL) {
    if (is.null(mw)) { mw = rep(1, nrow(x))/nrow(x) }
    if (any(is.infinite(logtype^apply(data, 2, function(x)
        return(sum(x[which(x>0)])))))) {
        Z <- getAffinity(x, logtype = logtype, mw = mw, data = data)
        l <- sum(apply(Z*(x + log(mw)/log(logtype)), 2, sum))
    } else {
        x <- logtype^x
        x <- x*mw
        l <- sum(log(apply(x, 2, sum))/log(logtype))
    }
    return(l)
}
#' @noRd
estimateSubtopo <- function(data) {
    effectsums <- effectsds <- matrix(0, nrow(data),
                                      length(unique(colnames(data))))
    for (i in seq_len(length(unique(colnames(data))))) {
        if (length(grep(i, colnames(data))) > 1) {
            effectsds[, i] <- apply(data[, grep(i, colnames(data))], 1, sd)
            effectsums[, i] <- apply(data[, grep(i, colnames(data))], 1, sum)
        } else {
            effectsds[, i] <- 1
            effectsums[, i] <- data[, grep(i, colnames(data))]
        }
    }
    subtopoX <- as.numeric(apply(effectsums/effectsds, 1, which.max))
    subtopoX[which(is.na(subtopoX) == TRUE)] <- 1
    return(subtopoX)
}
#' @noRd
getProbs <- function(probs, k, data, res, method = "llr", n, affinity = 0,
                     converged = 10^-2, subtopoX = NULL, ratio = TRUE,
                     logtype = 2, mw = NULL) {
    if (is.null(subtopoX)) {
        subtopoX <- estimateSubtopo(data)
    }
    subtopoY <- bestsubtopoY <- subtopoX
    bestprobs <- probsold <- probs
    time0 <- TRUE
    count <- 0
    max_count <- 100
    ll0 <- 0
    stop <- FALSE
    mw <- apply(getAffinity(probsold, affinity = affinity, norm = TRUE,
                            mw = mw, logtype = logtype, data = data), 1, sum)
    mw <- mw/sum(mw)
    if (any(is.na(mw))) { mw <- rep(1, k)/k }
    while((!stop | time0) & count < max_count) {
        llold <- max(ll0)
        time0 <- FALSE
        probsold <- probs
        subtopo0 <- matrix(0, k, nrow(data))
        subweights0 <- matrix(0, nrow(data), n+1) # account for null node
        postprobsold <- getAffinity(probsold, affinity = affinity, norm = TRUE,
                                    logtype = logtype, mw = mw, data = data)
        align <- list()
        for (i in seq_len(k)) {
            n <- getSgeneN(data)
            dataF <- matrix(0, nrow(data), n)
            colnames(dataF) <- seq_len(n)
            nozero <- which(postprobsold[i, ] != 0)
            if (length(nozero) != 0) {
                dataR <- cbind(data[, nozero, drop = FALSE], dataF)
                postprobsoldR <- c(postprobsold[i, nozero], rep(0, n))
            } else {
                dataR <- dataF
                postprobsoldR <- rep(0, n)
            }
            align[[i]] <- scoreAdj(dataR, res[[i]]$adj,
                                   method = method, ratio = ratio,
                                   weights = postprobsoldR)
            subtopo0[i, ] <- align[[i]]$subtopo
            subweights0 <- subweights0 + align[[i]]$subweights
        }
        subtopoMax <- apply(subweights0, 1, which.max)
        subtopoMax[which(subtopoMax > n)] <-
            subtopoMax[which(subtopoMax > n)] - n
        subtopo0 <- rbind(subtopoMax, subtopo0, subtopoX, subtopoY)
        probs0 <- list()
        ll0 <- numeric(nrow(subtopo0)+1)
        for (do in seq_len(nrow(subtopo0)+1)) {
            probs0[[do]] <- probsold*0
            if (do > 1) {
                subtopo <- subtopo0[do-1, ]
            }
            for (i in seq_len(k)) {
                if (do == 1) {
                    subtopo <- align[[i]]$subtopo
                }
                adj1 <- transitive.closure(res[[i]]$adj, mat = TRUE)
                adj1 <- cbind(adj1, "0" = 0)
                adj2 <- adj1[, subtopo]
                tmp <- llrScore(t(data), t(adj2), ratio = ratio)
                probs0[[do]][i, ] <-
                    tmp[cbind(seq_len(nrow(tmp)), as.numeric(rownames(tmp)))]
            }
            ll0[do] <- getLL(probs0[[do]], logtype = logtype, mw = mw,
                             data = data)
        }
        if (which.max(ll0) == 1) {
            sdo <- 1
        } else {
            sdo <- which.max(ll0) - 1
        }
        if (max(ll0) - llold > 0) {
            bestprobs <- probs0[[which.max(ll0)]]
            bestsubtopoY <- subtopo0[sdo, ]
        }
        probs <- probs0[[which.max(ll0)]]
        subtopoY <- subtopo0[sdo, ]
        if (max(ll0) - llold <= converged) {
            stop <- TRUE
        }
        mw <- apply(getAffinity(probs, affinity = affinity, norm = TRUE,
                                logtype = logtype, mw = mw, data = data), 1,
                    sum)
        mw <- mw/sum(mw)
        count <- count + 1
    }
    return(list(probs = bestprobs, subtopoX = bestsubtopoY))
}
#' @noRd
annotAdj <- function(adj, data) {
    Sgenes <- sort(unique(colnames(data)))
    colnames(adj) <- rownames(adj) <- sort(Sgenes)
    return(adj)
}
#' @noRd
nemEst <- function(data, maxiter = 100, start = "null",
                   sumf = mean, alpha = 1, cut = 0,
                   kernel = "cosim", monoton = FALSE,
                   useCut = TRUE, useF = FALSE, method = "llr",
                   weights = rep(1, ncol(data)), ...) {
    if (sum(duplicated(colnames(data)) == TRUE) > 0) {
        data2 <- data[, -which(duplicated(colnames(data)) == TRUE)]
        for (j in unique(colnames(data))) {
            data2[, j] <- apply(data[, which(colnames(data) %in% j),
                                     drop = FALSE], 1, sumf)
        }
    } else {
        data2 <- data
    }
    R <- data2[, naturalsort(colnames(data2))] 
    n <- ncol(R)
    if (kernel %in% "cosim") {
        R2 <- t(R)%*%R
    }
    if (kernel %in% "cor") {
        R2 <- cor(R)
    }
    if (!(kernel %in% c("cosim", "cor"))) {
        stop("kernel neither set to 'cosim' nor 'cor'.")
    }
    if (alpha < 1) {
        C <- cor(R)
        C <- C2 <- solve(C, ...)
        for (r in seq_len(nrow(C))) {
            C[r, ] <- C[r, ]/(C2[r, r]^0.5)
        }
        for (c in seq_len(ncol(C))) {
            C[, c] <- C[, c]/(C2[c, c]^0.5)
        }
        diag(C) <- 1
        Cz <- apply(C, c(1,2), function(x) return(0.5*log((1+x)/(1-x))))
        diag(Cz) <- 0
        Cz <- pnorm(((nrow(R) - n - 2 - 3)^0.5)*Cz)
        idx <- which(Cz >= alpha)
        Cp <- Cz
        Cp[-idx] <- 1
        Cp[idx] <- 0
    } else {
        Cp <- 1
        Cz <- 0
    }
    phibest <- phi <- matrix(0, n, n)
    rownames(phi) <- colnames(phi) <- colnames(R)
    E0 <- apply(R, 2, sum)
    phi <- phi[order(E0, decreasing = TRUE), order(E0, decreasing = TRUE)]
    phi[upper.tri(phi)] <- 1
    phi <- phi[naturalsort(rownames(phi)), naturalsort(colnames(phi))]
    phi <- transitive.closure(phi, mat = TRUE)
    E <- phi
    E <- E*Cp
    if (any(start %in% "full")) {
        phi <- phi
    } else if (any(start %in% "rand")) {
        phi <- phi*0
        diag(phi) <- 1
        phi[seq_len(length(phi))] <- sample(c(0,1), length(phi), replace = TRUE)
    } else if (any(start %in% "null")) {
        phi <- phi*0
        diag(phi) <- 1
    } else {
        phi <- start
    }
    O <- phi*0
    iter <- Oold <- 0
    lls <- NULL
    llbest <- -Inf
    stop <- FALSE
    while(!stop & iter < maxiter) {
        iter <- iter + 1
        if (method %in% "llr") {
            P <- t(t(R)*weights)%*%cbind(phi, 0)
        }
        if (method %in% "disc") {
            lltype <- "max"
            if (lltype %in% "max") { llfun <- max }
            if (lltype %in% "marg") { llfun <- sum }
            fp <- fn <- 0.1
            P <- ((1-fn)^(t(t(R)*weights)%*%phi))*
                (fn^((1-t(t(R)*weights))%*%phi))*
                (fp^(t(t(R)*weights)%*%(1-phi)))*
                ((1-fp)^((1-t(t(R)*weights))%*%(1-phi)))                                     
            P <- cbind(P, 0.5^nrow(R))
        }
        P[, grep("_", colnames(phi))] <- min(P)
        subtopo <- as.numeric(gsub(
            ncol(phi)+1, 0, apply(P, 1,function(x) return(which.max(x)))))
        theta <- t(R)*0
        theta[cbind(subtopo, seq_len(ncol(theta)))] <- 1
        Oold <- O
        if (method %in% "llr") {
            ll <- theta%*%P
            ll <- sum(diag(ll))
        }
        if (method %in% "disc") {
            ll <- sum(log(apply(P, 1, llfun)))
        }
        if (ll %in% lls | all(phi == phibest)) {
            stop <- TRUE
        }
        if (monoton & iter > 1) {
            if (ll < lls[length(lls)]) { stop <- TRUE }
        }
        if (llbest < ll) {
            phibest <- phi
            thetabest <- theta
            llbest <- ll
            numbest <- iter
            Obest <- O
        }
        lls <- c(lls, ll)
        nogenes <- which(apply(theta, 1, sum) == 0)
        nozeros <- which(t(P) > 0, arr.ind = TRUE)
        nozeros <- nozeros[which(nozeros[, 1] %in% nogenes), ]
        theta[nozeros] <- 1
        theta[grep("_", colnames(phi)), ] <- 0
        if (method %in% "llr") {
            if (useF) {
                O <- (t(R)*weights)%*%t(phi%*%theta)
            } else {
                O <- (t(R)*weights)%*%t(theta)
            }
        }
        if (method %in% "disc") {
            if (useF) {
                O <- (log(1-fn)*((t(R)*weights)%*%t(phi%*%theta)))+
                    (log(fn)*((1-(t(R)*weights))%*%t(phi%*%theta)))+
                    (log(fp)*((t(R)*weights)%*%t(1-phi%*%theta)))+
                    (log(1-fp)*((1-(t(R)*weights))%*%t(1-phi%*%theta)))
            } else {
                O <- (log(1-fn)*((t(R)*weights)%*%t(theta)))+
                    (log(fn)*((1-(t(R)*weights))%*%t(theta)))+
                    (log(fp)*((t(R)*weights)%*%t(1-theta)))+
                    (log(1-fp)*((1-(t(R)*weights))%*%t(1-theta)))
            }
        }
        if (useCut) {
            if (method %in% "llr") {
                cutoff <- cut*max(abs(O))
                phi[which(O > cutoff & E == 1)] <- 1
                phi[which(O <= cutoff | E == 0)] <- 0
            }
            if (method %in% "disc") {
                cutoff <- mean(O[which(E == 1)]) # cut*max(abs(O))
                phi[which(O > cutoff & E == 1)] <- 1
                phi[which(O <= cutoff | E == 0)] <- 0
            }
        } else {
            O <- O*E
            supertopo <- as.numeric(gsub(
                ncol(phi)+1, 0,apply(O, 1,
                                     function(x) return(which(x == max(x))))))
            phi <- phi*0
            phi[cbind(supertopo, seq_len(ncol(phi)))] <- 1
        }
    }
    phibest <- transitive.closure(phibest, mat = TRUE)
    if (method %in% "llr") {
        P <- t(t(R)*weights)%*%cbind(phibest, 0)
    }
    if (method %in% "disc") {
        P <- ((1-fn)^(t(t(R)*weights)%*%phibest))*
            (fn^((1-t(t(R)*weights))%*%phibest))*
            (fp^(t(t(R)*weights)%*%(1-phibest)))*
            ((1-fp)^((1-t(t(R)*weights))%*%(1-phibest)))                                     
        P <- cbind(P, 0.5^ncol(R))
    }
    P[, grep("_", colnames(phibest))] <- min(P)
    subtopo <- as.numeric(gsub(
        ncol(phibest)+1, 0, apply(P, 1, function(x) return(which.max(x)))))
    thetabest <- t(R)*0
    thetabest[cbind(subtopo, seq_len(ncol(thetabest)))] <- 1
    if (method %in% "llr") {
        llbest <- thetabest%*%P
        llbest <- sum(diag(llbest))
    }
    if (method %in% "disc") {
        llbest <- sum(log(apply(P, 1, llfun)))
    }
    nem <- list(phi = phibest, theta = thetabest, iter = iter,
                ll = llbest, lls = lls, num = numbest, C = Cz,
                O = Obest, E = E0)
    class(nem) <- "nemEst" 
    return(nem)
}
#' @noRd
modules <- function(D, method = "llr", weights = NULL, reduce = FALSE,
                    start = NULL,
                    verbose = FALSE, trans.close = TRUE, redSpace = NULL,
                    subtopo = NULL, ratio = TRUE, parallel = NULL,
                    prior = NULL,
                    modulesize = 4, search = "exhaustive", domean = TRUE) {
    D <- data <- modData(D)
    n <- getSgeneN(D)
    Sgenes <- getSgenes(D)
    if (domean) {
        mD <- matrix(0, nrow(D), length(Sgenes))
        if (!is.null(weights)) {
            D <- t(t(D)*weights)
            weights <- rep(1, ncol(mD))
        }
        for (i in seq_len(length(Sgenes))) {
            mD[, i] <-
                apply(D[, which(colnames(D) %in% i), drop = FALSE], 1, mean)
        }
        D <- mD
        colnames(D) <- seq_len(length(Sgenes))
        sumdata <- data <- D
    } else {
        sumdata <- matrix(0, nrow(data), n)
        if (!is.null(weights)) {
            D <- t(t(D)*weights)
            weights <- rep(1, ncol(sumdata))
        }
        for (i in seq_len(n)) {
            sumdata[, i] <-
                apply(D[, which(colnames(D) %in% i), drop = FALSE], 1, sum)
        }
        colnames(sumdata) <- seq_len(n)
        rownames(sumdata) <- rownames(D)
    }
    D <- NULL
    n <- getSgeneN(data)
    cordata <- cor(sumdata)
    cordata[is.na(cordata)] <- -1
    d <- as.dist((1 - cordata)/2)
    for (i in 2:n) {
        hc <- hclust(d)
        hcut <- cutree(hc, i)
        if (max(table(hcut)) <= modulesize) {
            break()
        }
    }
    groups <- table(hcut)
    fullnet <- NULL
    for (i in seq_len(length(groups))) {
        subset <- which(hcut == i)
        if (verbose) {
            print(paste(c("calculating module", subset), collapse = " "))
        }
        if (length(subset) > 1) {
            subdata <- data[, which(colnames(data) %in% subset)]
            if (is.null(start)) {
                start2 <- start
            } else {
                start2 <- start[which(rownames(start) %in% subset),
                                which(colnames(start) %in% subset)]
            }
            tmp <- mynem(subdata, search = search, method = method,
                         start = start2,
                         parallel = parallel, reduce = reduce,
                         weights = weights[which(colnames(data) %in% subset)],
                         verbose = verbose,
                         redSpace = redSpace, trans.close = trans.close,
                         subtopo = subtopo, prior = prior, ratio = ratio,
                         domean = FALSE)
            if (is.null(fullnet)) {
                fullnet <- tmp$adj
            } else {
                tmpnames <- c(colnames(fullnet), colnames(tmp$adj))
                fullnet <-
                    rbind(cbind(fullnet,
                                matrix(0, nrow(fullnet), ncol(tmp$adj))),
                          cbind(matrix(0, nrow(tmp$adj), ncol(fullnet)),
                                tmp$adj))
                colnames(fullnet) <- rownames(fullnet) <- as.numeric(tmpnames)
            }
        } else {
            if (is.null(dim(fullnet))) {
                fullnet <- matrix(1, 1, 1)
                colnames(fullnet) <- rownames(fullnet) <- subset
            } else {
                fullnet <- rbind(cbind(fullnet, 0), 0)
                colnames(fullnet)[ncol(fullnet)] <-
                    rownames(fullnet)[nrow(fullnet)] <-
                    subset
            }
        }
    }
    fullnet <- transitive.reduction(fullnet)
    fullnet <- fullnet[order(as.numeric(rownames(fullnet))),
                       order(as.numeric(colnames(fullnet)))]
    return(fullnet)
}
#' @noRd
getSgeneN <- function(data) {
    Sgenes <- length(unique(unlist(strsplit(colnames(data), ","))))
    return(Sgenes)
}
#' @noRd
getSgenes <- function(data) {
    Sgenes <- sort(as.numeric(unique(unlist(strsplit(colnames(data), ",")))))
    return(Sgenes)
}
#' @noRd
#' @importFrom nem enumerate.models transitive.closure transitive.reduction
#' @importFrom utils getFromNamespace
mynem <- function(D, search = "greedy", start = NULL, method = "llr",
                  parallel = NULL, reduce = FALSE, weights = NULL, runs = 1,
                  verbose = FALSE, redSpace = NULL,
                  trans.close = TRUE, subtopo = NULL, prior = NULL,
                  ratio = TRUE, domean = TRUE, modulesize = 5, ...) {
    get.deletions <- getFromNamespace("get.deletions", "nem")
    get.insertions <- getFromNamespace("get.insertions", "nem")
    get.reversions <- getFromNamespace("get.reversions", "nem")
    if (method %in% "disc") { domean = FALSE }
    if ("modules" %in% search) {
        if (length(search) > 1) {
            search <- search[-which(search %in% "modules")]
        } else {
            search <- "greedy"
        }
        if (length(unique(colnames(D))) > modulesize) {
            start <- modules(D, method = method, weights = weights,
                             reduce = reduce, verbose = verbose, start = start,
                             trans.close = trans.close, redSpace = redSpace,
                             subtopo = subtopo,
                             ratio = ratio, parallel = parallel, prior = prior,
                             modulesize = modulesize, search = search,
                             domean = domean)
        }
        if (search %in% "exhaustive") {
            search <- "greedy"
        }
    }
    D.backup <- D
    D <- modData(D)
    colnames(D) <- gsub("\\..*", "", colnames(D))
    Sgenes <- getSgenes(D)
    if (domean) {
        mD <- matrix(0, nrow(D), length(Sgenes))
        if (!is.null(weights)) {
            D <- t(t(D)*weights)
            weights <- rep(1, ncol(mD))
        }
        for (i in seq_len(length(Sgenes))) {
            mD[, i] <-
                apply(D[, which(colnames(D) %in% i), drop = FALSE], 1, mean)
        }
        D <- mD
        colnames(D) <- seq_len(length(Sgenes))
    }
    if (is.null(start)) {
        start2 <- "null"
        start <- better <- matrix(0, length(Sgenes), length(Sgenes))
    } else {
        if (length(start) == 1) {
            start2 <- start
            start <- better <- matrix(0, length(Sgenes), length(Sgenes))
        } else {
            better <- start2 <- start
        }
    }
    diag(start) <- diag(better) <- 1
    colnames(better) <- rownames(better) <-
        colnames(start) <- rownames(start) <- Sgenes
    score <- scoreAdj(D, better, method = method, weights = weights,
                      subtopo = subtopo,
                      prior = prior, ratio = ratio)
    score <- score$score
    oldscore <- score
    allscores <- score
    
    if (!is.null(parallel)) {
        sfInit(parallel = TRUE, cpus = parallel)
        sfExport("modules", "D", "start", "better", "transitive.closure",
                 "method", "scoreAdj", "weights", "transitive.closure",
                 "llrScore", "transitive.reduction")
    }

    if (search %in% "greedy") {
        for (iter in seq_len(runs)) {
            if (iter > 1) {
                better <- matrix(sample(c(0,1),nrow(better)*ncol(better),
                                       replace = TRUE),
                                nrow(better),
                                ncol(better))
                colnames(better) <- rownames(better) <-
                    sample(Sgenes, length(Sgenes))
                better[lower.tri(better)] <- 0
                diag(better) <- 1
                better <- better[order(as.numeric(rownames(better))),
                                 order(as.numeric(colnames(better)))]
                score <- scoreAdj(D, better, method = method,
                                  weights = weights,
                                  subtopo = subtopo, prior = prior,
                                  ratio = ratio)
                subtopo <- score$subtopo
                score <- score$score
                oldscore <- score
                allscores <- score
            }
            stop <- FALSE
            while(!stop) {
                doScores <- function(i) {
                    new <- models[[i]]
                    score <- scoreAdj(D, new, method = method,
                                      weights = weights,
                                      subtopo = subtopo, prior = prior,
                                      ratio = ratio)
                    subtopo <- score$subtopo
                    score <- score$score
                    return(score)
                }
                models <- unique(c(get.insertions(better),
                                   get.reversions(better),
                                   get.deletions(better)))
                if (is.null(parallel)) {
                    scores <- unlist(lapply((seq_len(length(models))),
                                            doScores))
                } else {
                    scores <- unlist(sfLapply((seq_len(length(models))),
                                              doScores))
                }
                scores[is.na(scores)] <- 0
                best <- models[[which.max(scores)]]
                best <- transitive.closure(best, mat = TRUE)
                if (max(scores, na.rm = TRUE) > oldscore |
                    (max(scores, na.rm = TRUE) == oldscore &
                     sum(better == 1) > sum(best == 1))) {
                    better <- best
                    better <- transitive.closure(better, mat = TRUE)
                    oldscore <- max(scores)
                    allscores <- c(allscores, oldscore)
                } else {
                    stop <- TRUE
                }
            }
            if (iter > 1) {
                if (oldscore > oldscore2) {
                    better2 <- better
                    allscores2 <- allscores
                    oldscore2 <- oldscore
                }
            } else {
                better2 <- better
                allscores2 <- allscores
                oldscore2 <- oldscore
            }
        }
        better <- better2
        allscores <- allscores2
        oldscore <- oldscore2
    }

    if (search %in% "exhaustive") {
        models <- enumerate.models(length(Sgenes), Sgenes,
                                   trans.close = trans.close,
                                   verbose = verbose)
        doScores <- function(i) {
            adj <- models[[i]]
            score <- scoreAdj(D, adj, method = method, weights = weights,
                              subtopo = subtopo, prior = prior,
                              ratio = ratio)
            subtopo <- score$subtopo
            score <- score$score
            return(score)
        }
        if (is.null(parallel)) {
            scores <- unlist(lapply(seq_len(length(models)), doScores))
        } else {
            scores <- unlist(sfLapply(seq_len(length(models)), doScores))
        }
        best <- which.max(scores)
        better <- transitive.closure(models[[best]], mat = TRUE)
        diag(better) <- 1
    }
    
    if (search %in% "estimate") {
        if (!is.null(weights)) {
            Dw <- t(t(D)*weights)
        } else {
            Dw <- D
        }
        tmp <- nemEst(Dw, start = start2, method = method, ...)
        better <- tmp$phi
        oldscore <- tmp$ll
        allscores <- tmp$lls
        subweights <- Dw%*%cbind(tmp$phi[colnames(Dw), ], 0)
        subtopo <- apply(subweights, 1, which.max)
    }
    
    if (!is.null(parallel)) {
        sfStop()
    }
    
    subtopo <- scoreAdj(D, better, method = method, weights = weights,
                        subtopo = subtopo, prior = prior,
                        ratio = ratio)
    subweights <- subtopo$subweights
    subtopo <- subtopo$subtopo
    
    better <- transitive.reduction(better)
    better <- better[order(as.numeric(rownames(better))),
                     order(as.numeric(colnames(better)))]
    nem <- list(adj = better, score = oldscore, scores = allscores,
                redSpace = redSpace, subtopo = subtopo, D = D.backup,
                subweights = subweights)
    return(nem)
}
#' @noRd
adj2dnf <- function(A) {

    dnf <- NULL
    
    for (i in seq_len(ncol(A))) {
        for (j in seq_len(nrow(A))) {
            if (i %in% j) { next() }
            if (A[i, j] == 1) {
                dnf <- c(dnf, paste(colnames(A)[i], rownames(A)[j], sep = "="))
            }
            if (A[i, j] == -1) {
                dnf <- c(dnf, paste("!", colnames(A)[i], "=",
                                    rownames(A)[j], sep = ""))
            }
        }
    }

    dnf <- unique(dnf)
    
    return(dnf)

}
#' @noRd
#' @importFrom methods new
plot.adj <- function(x, ...) {
    adj2graph <- function(adj.matrix) {
        V   <- rownames(adj.matrix)
        edL <- vector("list", length=nrow(adj.matrix))
        names(edL) <- V
        for (i in seq_len(nrow(adj.matrix))) {
            edL[[i]] <- list(edges=which(!adj.matrix[i,]==0),
                             weights=adj.matrix[i,!adj.matrix[i,]==0])
        }
        gR <- new("graphNEL",nodes=V,edgeL=edL,edgemode="directed")
        return(gR)
    }
    g <- adj2graph(x)
    plot(g)
}
#' @noRd
graph2adj <- function(gR) {
    adj.matrix <- matrix(0,
                         length(nodes(gR)),
                         length(nodes(gR))
                         )
    rownames(adj.matrix) <- nodes(gR)
    colnames(adj.matrix) <- nodes(gR)
    for (i in seq_len(length(nodes(gR)))) {
        adj.matrix[nodes(gR)[i],adj(gR,nodes(gR)[i])[[1]]] <- 1
    }
    return(adj.matrix)
}
#' @noRd
#' @importFrom flexclust dist2
llrScore <- function(data, adj, weights = NULL, ratio = TRUE) {
    if (is.null(weights)) {
        weights <- rep(1, ncol(data))
    }
    if (ratio) {
        score <- data%*%(adj*weights)
    } else {
        if (max(data) == 1) {
            score <- -dist2(data, t(adj)*weights)
        } else {
            score <- -dist2(data, t((adj*mean(data))*weights))
        }
    }
    return(score)
}
#' @noRd
discScore <- function(data, adj, weights = NULL) {
    fp <- fn <- 0.1
    tp <- tn <- 0.9
    if (is.null(weights)) {
        weights <- rep(1, ncol(data))
        score <- (tp^(data%*%adj))*
            (fn^((1-data)%*%adj))*
            (fp^(data%*%(1-adj)))*
            (tn^((1-data)%*%(1-adj)))
    } else {
        fp <- t(matrix(fp/(weights - 2*fp*(1-weights)), ncol(data), nrow(data)))
        fn <- t(matrix(fn/(weights - 2*fn*(1-weights)), ncol(data), nrow(data)))
        tp <- t(matrix(tp/(weights - 2*tp*(1-weights)), ncol(data), nrow(data)))
        tn <- t(matrix(tn/(weights - 2*tn*(1-weights)), ncol(data), nrow(data)))
        score <- (tp^(data%*%adj))*
            (fn^((1-data)%*%adj))*
            (fp^(data%*%(1-adj)))*
            (tn^((1-data)%*%(1-adj)))
    }
    score <- cbind(score, 0.5^nrow(data))
    return(score)
}
#' @noRd
scoreAdj <- function(D, adj, method = "llr", weights = NULL,
                     trans.close = TRUE, subtopo = NULL,
                     prior = NULL, ratio = TRUE) {
    adj <- transitive.closure(adj, mat = TRUE)
    adj1 <- cbind(adj[colnames(D), ], "0" = 0)
    if (method %in% "llr") {
        ll <- "max"
        score <- llrScore(D, adj1, weights = weights, ratio = ratio)
    }
    if (method %in% "disc") {
        ll <- "marg"
        score <- discScore(D, adj, weights = weights)
    }
    if (is.null(subtopo)) {
        subtopo <- apply(score, 1, which.max)
    }
    subweights <- score
    if (ll %in% "max") {
        score <- sum(score[cbind(seq_len(nrow(score)), subtopo)])
    }
    if (ll %in% "marg") {
        score <- sum(log(apply(score, 1, sum)))
    }
    if (!is.null(prior)) {
        prior <- transitive.reduction(prior)
        adj <- transitive.reduction(adj)
    } else {
        prior <- adj
    }
    score <- score - sum(abs(prior - adj))/length(prior)
    return(list(score = score, subtopo = subtopo, subweights = subweights))
}
#' @noRd
adj2dnf <- function(A) {

    dnf <- NULL
    
    for (i in seq_len(ncol(A))) {
        dnf <- c(dnf, rownames(A))
        for (j in seq_len(nrow(A))) {
            ## if (i %in% j) { next() }
            if (A[i, j] == 1) {
                dnf <- c(dnf, paste(colnames(A)[i], rownames(A)[j], sep = "="))
            }
            if (A[i, j] == -1) {
                dnf <- c(dnf, paste("!", colnames(A)[i], "=", rownames(A)[j],
                                    sep = ""))
            }
        }
    }
    
    dnf <- unique(dnf)
    
    return(dnf)
    
}
#' @noRd
simulateDnf <- function(dnf, stimuli = NULL, inhibitors = NULL) {
    getStateDnf <- function(node, signalStates, graph, children = NULL) {
        graphCut <- graph[grep(paste("=", node, "$", sep = ""), graph)]
        if (length(graphCut) == 0) {
            signalStates[, node] <- 0
        } else {
            sop <- numeric(nrow(signalStates))
            children2 <- gsub("!", "", children)
            for (i in graphCut) {
                parents <- gsub("=.*$", "", unlist(strsplit(i, "\\+")))
                pob <- rep(1, nrow(signalStates))
                for (j in parents) {
                    j2 <- gsub("!", "", j)
                    if (sum(is.na(signalStates[, j2]) == TRUE) ==
                        length(signalStates[, j2])) {
                        if (j %in% j2) {
                            node2 <- node
                            add1 <- 0
                        } else {
                            node2 <- paste("!", node, sep = "")
                            add1 <- 1
                        }
                        if (j2 %in% children2) {
                            subGraph <- graph[
                                -grep(paste(".*=", node, "|.*",
                                            j2, ".*=.*", sep = ""), graph)]
                            signalStatesTmp <- getStateDnf(
                                node = j2,
                                signalStates = signalStates,
                                graph = subGraph,
                                children = NULL)
                            ifa <- children[
                                which(children2 %in% j2):length(children2)]
                            ifb <- (length(grep("!", ifa)) + add1)/2
                            ifc <- children[
                                which(children2 %in% j2):length(children2)]
                            if (ifb != ceiling((length(grep("!", ifc)) +
                                                add1)/2)) {
                            } else {
                            }
                            if (add1 == 0) {
                                pobMult <- signalStatesTmp[, j2]
                            } else {
                                pobMult <- add1 - signalStatesTmp[, j2]
                            }
                        } else {
                            signalStates <-
                                getStateDnf(node = j2,
                                            signalStates = signalStates,
                                            graph = graph,
                                            children = unique(c(children,
                                                                node2)))
                            if (add1 == 0) {
                                pobMult <- signalStates[, j2]
                            } else {
                                pobMult <- add1 - signalStates[, j2]
                            }
                        }
                        pob <- pob*pobMult
                    } else {
                        if (j %in% j2) {
                            add1 <- 0
                        } else {
                            add1 <- 1
                        }
                        if (add1 == 0) {
                            pobMult <- signalStates[, j2]
                        } else {
                            pobMult <- add1 - signalStates[, j2]
                        }
                        pob <- pob*pobMult
                    }
                    if (max(pob, na.rm = TRUE) == 0) { break() }
                }
                sop <- sop + pob
                if (min(sop, na.rm = TRUE) > 0) { break() }
            }
            sop[sop > 0] <- 1
            if (node %in% inhibitors) {
                sop <- sop*0
            }
            if (node %in% stimuli) {
                sop <- max(sop, 1)
            }
            signalStates[, node] <- sop
        }
        return(signalStates)
    }
    signals <-
        unique(gsub("!", "",
                    unlist(strsplit(
                        unlist(strsplit(dnf, "=")), "\\+"))))
    graph <- dnf
    signalStates <- matrix(NA, nrow = 1, ncol = length(signals))
    rownames(signalStates) <- paste(c("stimuli:", stimuli, "inhibitors:",
                                      inhibitors), collapse = " ")
    colnames(signalStates) <- signals
    signalStates[which(signals %in% stimuli)] <- 1
    for (k in signals) {
        if (is.na(signalStates[, k]) == TRUE) {
            signalStates <- getStateDnf(node = k, signalStates = signalStates,
                                        graph = graph, children = NULL)
        }
    }
    namestmp <- colnames(signalStates)
    signalStates <- as.vector(signalStates)
    names(signalStates) <- namestmp
    return(signalStates = signalStates)
}
