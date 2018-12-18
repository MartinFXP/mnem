// Generated by using Rcpp::compileAttributes() -> do not edit by hand
// Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

#include <RcppEigen.h>
#include <Rcpp.h>

using namespace Rcpp;

// eigenMapMatMult
SEXP eigenMapMatMult(const Eigen::Map<Eigen::MatrixXd> A, Eigen::Map<Eigen::MatrixXd> B);
RcppExport SEXP _mnem_eigenMapMatMult(SEXP ASEXP, SEXP BSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< const Eigen::Map<Eigen::MatrixXd> >::type A(ASEXP);
    Rcpp::traits::input_parameter< Eigen::Map<Eigen::MatrixXd> >::type B(BSEXP);
    rcpp_result_gen = Rcpp::wrap(eigenMapMatMult(A, B));
    return rcpp_result_gen;
END_RCPP
}
// transClose_W
SEXP transClose_W(Rcpp::NumericMatrix x);
RcppExport SEXP _mnem_transClose_W(SEXP xSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< Rcpp::NumericMatrix >::type x(xSEXP);
    rcpp_result_gen = Rcpp::wrap(transClose_W(x));
    return rcpp_result_gen;
END_RCPP
}
// transClose_Del
SEXP transClose_Del(Rcpp::NumericMatrix x, Rcpp::IntegerVector u, Rcpp::IntegerVector v);
RcppExport SEXP _mnem_transClose_Del(SEXP xSEXP, SEXP uSEXP, SEXP vSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< Rcpp::NumericMatrix >::type x(xSEXP);
    Rcpp::traits::input_parameter< Rcpp::IntegerVector >::type u(uSEXP);
    Rcpp::traits::input_parameter< Rcpp::IntegerVector >::type v(vSEXP);
    rcpp_result_gen = Rcpp::wrap(transClose_Del(x, u, v));
    return rcpp_result_gen;
END_RCPP
}
// transClose_Ins
SEXP transClose_Ins(Rcpp::NumericMatrix x, Rcpp::IntegerVector u, Rcpp::IntegerVector v);
RcppExport SEXP _mnem_transClose_Ins(SEXP xSEXP, SEXP uSEXP, SEXP vSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< Rcpp::NumericMatrix >::type x(xSEXP);
    Rcpp::traits::input_parameter< Rcpp::IntegerVector >::type u(uSEXP);
    Rcpp::traits::input_parameter< Rcpp::IntegerVector >::type v(vSEXP);
    rcpp_result_gen = Rcpp::wrap(transClose_Ins(x, u, v));
    return rcpp_result_gen;
END_RCPP
}
// maxCol_row
SEXP maxCol_row(Rcpp::NumericMatrix x);
RcppExport SEXP _mnem_maxCol_row(SEXP xSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< Rcpp::NumericMatrix >::type x(xSEXP);
    rcpp_result_gen = Rcpp::wrap(maxCol_row(x));
    return rcpp_result_gen;
END_RCPP
}

static const R_CallMethodDef CallEntries[] = {
    {"_mnem_eigenMapMatMult", (DL_FUNC) &_mnem_eigenMapMatMult, 2},
    {"_mnem_transClose_W", (DL_FUNC) &_mnem_transClose_W, 1},
    {"_mnem_transClose_Del", (DL_FUNC) &_mnem_transClose_Del, 3},
    {"_mnem_transClose_Ins", (DL_FUNC) &_mnem_transClose_Ins, 3},
    {"_mnem_maxCol_row", (DL_FUNC) &_mnem_maxCol_row, 1},
    {NULL, NULL, 0}
};

RcppExport void R_init_mnem(DllInfo *dll) {
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
