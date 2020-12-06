/**
 * @file
 * Implements Envelopes strategy the Envelopes indicator.
 */

// Includes.
#include <EA31337-classes/Indicators/Indi_Envelopes.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
INPUT float Envelopes_LotSize = 0;               // Lot size
INPUT int Envelopes_SignalOpenMethod = 48;       // Signal open method (-127-127)
INPUT float Envelopes_SignalOpenLevel = 0;       // Signal open level
INPUT int Envelopes_SignalOpenFilterMethod = 0;  // Signal open filter method
INPUT int Envelopes_SignalOpenBoostMethod = 0;   // Signal open filter method
INPUT int Envelopes_SignalCloseMethod = 48;      // Signal close method (-127-127)
INPUT float Envelopes_SignalCloseLevel = 0;      // Signal close level
INPUT int Envelopes_PriceStopMethod = 0;         // Price stop method
INPUT float Envelopes_PriceStopLevel = 0;        // Price stop level
INPUT int Envelopes_TickFilterMethod = 0;        // Tick filter method
INPUT float Envelopes_MaxSpread = 6.0;           // Max spread to trade (pips)
INPUT int Envelopes_Shift = 0;                   // Shift
INPUT string __Envelopes_Indi_Envelopes_Parameters__ =
    "-- Envelopes strategy: Envelopes indicator params --";  // >>> Envelopes strategy: Envelopes indicator <<<
INPUT int Indi_Envelopes_MA_Period = 6;                      // Period
INPUT int Indi_Envelopes_MA_Shift = 0;                       // MA Shift
INPUT ENUM_MA_METHOD Indi_Envelopes_MA_Method = 3;           // MA Method
INPUT ENUM_APPLIED_PRICE Indi_Envelopes_Applied_Price = 3;   // Applied Price
INPUT float Indi_Envelopes_Deviation = 0.5;                  // Deviation for M1

// Structs.

// Defines struct with default user indicator values.
struct Indi_Envelopes_Params_Defaults : EnvelopesParams {
  Indi_Envelopes_Params_Defaults()
      : EnvelopesParams(::Indi_Envelopes_MA_Period, ::Indi_Envelopes_MA_Shift, ::Indi_Envelopes_MA_Method,
                        ::Indi_Envelopes_Applied_Price, ::Indi_Envelopes_Deviation) {}
} indi_envelopes_defaults;

// Defines struct to store indicator parameter values.
struct Indi_Envelopes_Params : public EnvelopesParams {
  // Struct constructors.
  void Indi_Envelopes_Params(EnvelopesParams &_params, ENUM_TIMEFRAMES _tf) : EnvelopesParams(_params, _tf) {}
};

// Defines struct with default user strategy values.
struct Stg_Envelopes_Params_Defaults : StgParams {
  Stg_Envelopes_Params_Defaults()
      : StgParams(::Envelopes_SignalOpenMethod, ::Envelopes_SignalOpenFilterMethod, ::Envelopes_SignalOpenLevel,
                  ::Envelopes_SignalOpenBoostMethod, ::Envelopes_SignalCloseMethod, ::Envelopes_SignalCloseLevel,
                  ::Envelopes_PriceStopMethod, ::Envelopes_PriceStopLevel, ::Envelopes_TickFilterMethod,
                  ::Envelopes_MaxSpread, ::Envelopes_Shift) {}
} stg_envelopes_defaults;

// Struct to define strategy parameters to override.
struct Stg_Envelopes_Params : StgParams {
  Indi_Envelopes_Params iparams;
  StgParams sparams;

  // Struct constructors.
  Stg_Envelopes_Params(Indi_Envelopes_Params &_iparams, StgParams &_sparams)
      : iparams(indi_envelopes_defaults, _iparams.tf), sparams(stg_envelopes_defaults) {
    iparams = _iparams;
    sparams = _sparams;
  }
};

// Loads pair specific param values.
#include "config/EURUSD_H1.h"
#include "config/EURUSD_H4.h"
#include "config/EURUSD_H8.h"
#include "config/EURUSD_M1.h"
#include "config/EURUSD_M15.h"
#include "config/EURUSD_M30.h"
#include "config/EURUSD_M5.h"

class Stg_Envelopes : public Strategy {
 public:
  Stg_Envelopes(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_Envelopes *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Indi_Envelopes_Params _indi_params(indi_envelopes_defaults, _tf);
    StgParams _stg_params(stg_envelopes_defaults);
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<Indi_Envelopes_Params>(_indi_params, _tf, indi_envelopes_m1, indi_envelopes_m5, indi_envelopes_m15,
                                           indi_envelopes_m30, indi_envelopes_h1, indi_envelopes_h4, indi_envelopes_h8);
      SetParamsByTf<StgParams>(_stg_params, _tf, stg_envelopes_m1, stg_envelopes_m5, stg_envelopes_m15,
                               stg_envelopes_m30, stg_envelopes_h1, stg_envelopes_h4, stg_envelopes_h8);
    }
    // Initialize indicator.
    EnvelopesParams env_params(_indi_params);
    _stg_params.SetIndicator(new Indi_Envelopes(_indi_params));
    // Initialize strategy parameters.
    _stg_params.GetLog().SetLevel(_log_level);
    _stg_params.SetMagicNo(_magic_no);
    _stg_params.SetTf(_tf, _Symbol);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_Envelopes(_stg_params, "Envelopes");
    _stg_params.SetStops(_strat, _strat);
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Chart *_chart = sparams.GetChart();
    Indi_Envelopes *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    bool _result = _is_valid;
    if (!_result) {
      // Returns false when indicator data is not valid.
      return false;
    }
    double level = _level * Chart().GetPipSize();
    double ask = Chart().GetAsk();
    double bid = Chart().GetBid();
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result = Low[CURR] < _indi[CURR][LINE_LOWER] ||
                  Low[PREV] < _indi[CURR][LINE_LOWER];  // price low was below the lower band
        // _result = _result || (_indi[CURR]_main > _indi[PPREV]_main && Open[CURR] > _indi[CURR][LINE_UPPER]);
        if (_method != 0) {
          if (METHOD(_method, 0)) _result &= Chart().GetOpen() > _indi[CURR][LINE_LOWER];  // FIXME
          if (METHOD(_method, 1))
            _result &= (_indi[CURR][LINE_UPPER] - _indi[CURR][LINE_LOWER]) / 2 <
                       (_indi[PREV][LINE_UPPER] - _indi[PREV][LINE_LOWER]) / 2;
          if (METHOD(_method, 2)) _result &= _indi[CURR][LINE_LOWER] < _indi[PREV][LINE_LOWER];
          if (METHOD(_method, 3)) _result &= _indi[CURR][LINE_UPPER] < _indi[PREV][LINE_UPPER];
          if (METHOD(_method, 4))
            _result &=
                _indi[CURR][LINE_UPPER] - _indi[CURR][LINE_LOWER] > _indi[PREV][LINE_UPPER] - _indi[PREV][LINE_LOWER];
          if (METHOD(_method, 5)) _result &= ask < (_indi[CURR][LINE_UPPER] - _indi[CURR][LINE_LOWER]) / 2;
          if (METHOD(_method, 6)) _result &= Chart().GetClose() < _indi[CURR][LINE_UPPER];
          // if (METHOD(_method, 7)) _result &= _chart.GetAsk() > Close[PREV];
        }
        break;
      case ORDER_TYPE_SELL:
        _result = High[CURR] > _indi[CURR][LINE_UPPER] ||
                  High[PREV] > _indi[CURR][LINE_UPPER];  // price high was above the upper band
        // _result = _result || (_indi[CURR]_main < _indi[PPREV]_main && Open[CURR] < _indi[CURR][LINE_LOWER]);
        if (_method != 0) {
          if (METHOD(_method, 0)) _result &= Chart().GetOpen() < _indi[CURR][LINE_UPPER];  // FIXME
          if (METHOD(_method, 1))
            _result &= (_indi[CURR][LINE_UPPER] - _indi[CURR][LINE_LOWER]) / 2 >
                       (_indi[PREV][LINE_UPPER] - _indi[PREV][LINE_LOWER]) / 2;
          if (METHOD(_method, 2)) _result &= _indi[CURR][LINE_LOWER] > _indi[PREV][LINE_LOWER];
          if (METHOD(_method, 3)) _result &= _indi[CURR][LINE_UPPER] > _indi[PREV][LINE_UPPER];
          if (METHOD(_method, 4))
            _result &=
                _indi[CURR][LINE_UPPER] - _indi[CURR][LINE_LOWER] > _indi[PREV][LINE_UPPER] - _indi[PREV][LINE_LOWER];
          if (METHOD(_method, 5)) _result &= ask > (_indi[CURR][LINE_UPPER] - _indi[CURR][LINE_LOWER]) / 2;
          if (METHOD(_method, 6)) _result &= Chart().GetClose() > _indi[CURR][LINE_UPPER];
          // if (METHOD(_method, 7)) _result &= _chart.GetAsk() < Close[PREV];
        }
        break;
    }
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0) {
    return SignalOpen(Order::NegateOrderType(_cmd), _method, _level);
  }

  /**
   * Gets price stop value for profit take or stop loss.
   */
  float PriceStop(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
    Indi_Envelopes *_indi = Data();
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _direction;
    double _result = _default_value;

    if (GetLastError() > ERR_INDICATOR_DATA_NOT_FOUND) {
      // Returns false when indicator data is not ready.
      return false;
    }
    switch (_method) {
      case 1: {
        _result = (_direction > 0 ? _indi[CURR][LINE_UPPER] : _indi[CURR][LINE_LOWER]) + _trail * _direction;
        break;
      }
      case 2: {
        _result = (_direction > 0 ? _indi[PREV][LINE_UPPER] : _indi[PREV][LINE_LOWER]) + _trail * _direction;
        break;
      }
      case 3: {
        _result = (_direction > 0 ? _indi[PPREV][LINE_UPPER] : _indi[PPREV][LINE_LOWER]) + _trail * _direction;
        break;
      }
      case 4: {
        _result = (_direction > 0 ? fmax(_indi[PREV][LINE_UPPER], _indi[PPREV][LINE_UPPER])
                                  : fmin(_indi[PREV][LINE_LOWER], _indi[PPREV][LINE_LOWER])) +
                  _trail * _direction;
        break;
      }
      case 5: {
        _result = (_indi[CURR][LINE_UPPER] - _indi[CURR][LINE_LOWER]) / 2 + _trail * _direction;
        break;
      }
      case 6: {
        _result = (_indi[PREV][LINE_UPPER] - _indi[PREV][LINE_LOWER]) / 2 + _trail * _direction;
        break;
      }
      case 7: {
        _result = (_indi[PPREV][LINE_UPPER] - _indi[PPREV][LINE_LOWER]) / 2 + _trail * _direction;
        break;
      }
      case 8: {
        int _bar_count = (int)_level * (int)_indi.GetMAPeriod();
        _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest<double>(_bar_count))
                                 : _indi.GetPrice(PRICE_LOW, _indi.GetLowest<double>(_bar_count));
        break;
      }
    }
    return (float)_result;
  }
};
