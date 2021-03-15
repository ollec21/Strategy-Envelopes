/**
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_Envelopes_Params_M30 : EnvelopesParams {
  Indi_Envelopes_Params_M30() : EnvelopesParams(indi_env_defaults, PERIOD_M30) {
    applied_price = (ENUM_APPLIED_PRICE)2;
    deviation = 0.07;
    ma_method = (ENUM_MA_METHOD)2;
    ma_period = 15;
    ma_shift = 3;
    shift = 0;
  }
} indi_env_m30;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_Envelopes_Params_M30 : StgParams {
  // Struct constructor.
  Stg_Envelopes_Params_M30() : StgParams(stg_env_defaults) {
    lot_size = 0;
    signal_open_method = 0;
    signal_open_filter = 1;
    signal_open_level = (float)0.0;
    signal_open_boost = 0;
    signal_close_method = 0;
    signal_close_level = (float)0;
    price_stop_method = 0;
    price_stop_level = (float)1;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_env_m30;
