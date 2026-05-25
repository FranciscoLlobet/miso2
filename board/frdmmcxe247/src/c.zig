pub const c = @cImport({
    @cInclude("cimport.h");
    @cInclude("fsl_gpio.h");
    @cInclude("fsl_phy.h");
    @cInclude("fsl_phylan8741.h");
    @cInclude("fsl_silicon_id.h");
});
