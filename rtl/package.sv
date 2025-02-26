// Precision-scalable CNN accelerator (PSCA) package
package psca_pkg;
    typedef enum logic [1:0] {
        _8x8  = 2'b00,
        _4x4  = 2'b01,
        _2x2  = 2'b10
    } P_MODE;

    parameter DATA_WIDTH = 8;

    // Memory Configuration
    parameter SPAD_I_W = 64; // Input SPAD Data Width
    parameter SPAD_I_DEPTH = 256; // Input SPAD Depth
    parameter SPAD_I_AW = $clog($clog(SPADI_DEPTH), 2); // Input SPAD Address Width
    parameter SPAD_I_N = SPAD_I_W / DATA_WIDTH; // Number of data in a SPAD word

    parameter SPAD_O_W = 64; // Output SPAD Data Width
    parameter SPAD_O_DEPTH = 256; // Output SPAD Depth
    parameter SPAD_O_AW = $clog($clog(SPADO_DEPTH), 2); // Output SPAD Address Width
    parameter SPAD_O_N = SPAD_O_W / DATA_WIDTH; // Number of data in a SPAD word

    parameter SPAD_W_W = 64; // Weight SPAD Data Width
    parameter SPAD_W_DEPTH = 256; // Weight SPAD Depth
    parameter SPAD_W_AW = $clog($clog(SPADW_DEPTH), 2); // Weight SPAD Address Width
    parameter SPAD_W_N = SPAD_W_W / DATA_WIDTH; // Number of data in a SPAD word

    // Systolic Array Configuration
    parameter SA_H = 8; // Systolic Array Height
    parameter SA_W = 1; // Systolic Array Width

    // Input Router Configuration
    parameter PEEK_WIDTH = 8; // Number of data to be peeked from MPP FIFO

    // FIFO Configuration
    parameter MPP_DEPTH = 9; // MPP FIFO Depth
    parameter MISO_DEPTH = 16; // MISO FIFO Depth

endpackage