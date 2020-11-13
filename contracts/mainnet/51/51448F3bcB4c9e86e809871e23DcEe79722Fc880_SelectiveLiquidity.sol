pragma solidity ^0.5.0;

library SelectiveLiquidity {

    using ABDKMath64x64 for int128;
    using UnsafeMath64x64 for int128;

    event Transfer(address indexed from, address indexed to, uint256 value);

    int128 constant ONE = 0x10000000000000000;

    function selectiveDeposit (
        LoihiStorage.Shell storage shell,
        address[] calldata _derivatives,
        uint[] calldata _amounts,
        uint _minShells
    ) external returns (
        uint shells_
    ) {

        (   int128 _oGLiq,
            int128 _nGLiq,
            int128[] memory _oBals,
            int128[] memory _nBals ) = getLiquidityDepositData(shell, _derivatives, _amounts);

        int128 _shells;
        ( _shells, shell.omega ) = ShellMath.calculateLiquidityMembrane(shell, _oGLiq, _nGLiq, _oBals, _nBals);

        shells_ = _shells.mulu(1e18);

        require(_minShells < shells_, "Shell/under-minimum-shells");

        mint(shell, msg.sender, shells_);

    }

    function viewSelectiveDeposit (
        LoihiStorage.Shell storage shell,
        address[] calldata _derivatives,
        uint[] calldata _amounts
    ) external view returns (
        uint shells_
    ) {

        (   int128 _oGLiq,
            int128 _nGLiq,
            int128[] memory _oBals,
            int128[] memory _nBals ) = viewLiquidityDepositData(shell, _derivatives, _amounts);

        ( int128 _shells, ) = ShellMath.calculateLiquidityMembrane(shell, _oGLiq, _nGLiq, _oBals, _nBals);

        shells_ = _shells.mulu(1e18);

    }


    function selectiveWithdraw (
        LoihiStorage.Shell storage shell,
        address[] calldata _derivatives,
        uint[] calldata _amounts,
        uint _maxShells
    ) external returns (
        uint256 shells_
    ) {

        (   int128 _oGLiq,
            int128 _nGLiq,
            int128[] memory _oBals,
            int128[] memory _nBals ) = getLiquidityWithdrawData(shell, _derivatives, msg.sender, _amounts);

        int128 _shells;

        ( _shells, shell.omega ) = ShellMath.calculateLiquidityMembrane(shell, _oGLiq, _nGLiq, _oBals, _nBals);

        _shells = _shells.abs().us_mul(ONE + shell.epsilon);

        shells_ = _shells.mulu(1e18);

        require(shells_ < _maxShells, "Shell/above-maximum-shells");

        burn(shell, msg.sender, shells_);

    }

    function viewSelectiveWithdraw (
        LoihiStorage.Shell storage shell,
        address[] calldata _derivatives,
        uint[] calldata _amounts
    ) external view returns (
        uint shells_
    ) {

        (   int128 _oGLiq,
            int128 _nGLiq,
            int128[] memory _oBals,
            int128[] memory _nBals ) = viewLiquidityWithdrawData(shell, _derivatives, _amounts);

        ( int128 _shells, ) = ShellMath.calculateLiquidityMembrane(shell, _oGLiq, _nGLiq, _oBals, _nBals);

        _shells = _shells.abs().us_mul(ONE + shell.epsilon);

        shells_ = _shells.mulu(1e18);

    }

    function getLiquidityDepositData (
        LoihiStorage.Shell storage shell,
        address[] memory _derivatives,
        uint[] memory _amounts
    ) private returns (
        int128 oGLiq_,
        int128 nGLiq_,
        int128[] memory,
        int128[] memory
    ) {

        uint _length = shell.weights.length;
        int128[] memory oBals_ = new int128[](_length);
        int128[] memory nBals_ = new int128[](_length);

        for (uint i = 0; i < _derivatives.length; i++) {

            LoihiStorage.Assimilator memory _assim = shell.assimilators[_derivatives[i]];

            require(_assim.addr != address(0), "Shell/unsupported-derivative");

            if ( nBals_[_assim.ix] == 0 && oBals_[_assim.ix] == 0 ) {

                ( int128 _amount, int128 _balance ) = Assimilators.intakeRawAndGetBalance(_assim.addr, _amounts[i]);

                nBals_[_assim.ix] = _balance;

                oBals_[_assim.ix] = _balance.sub(_amount);

            } else {

                int128 _amount = Assimilators.intakeRaw(_assim.addr, _amounts[i]);

                nBals_[_assim.ix] = nBals_[_assim.ix].sub(_amount);

            }

        }

        return completeLiquidityData(shell, oBals_, nBals_);

    }

    function getLiquidityWithdrawData (
        LoihiStorage.Shell storage shell,
        address[] memory _derivatives,
        address _rcpnt,
        uint[] memory _amounts
    ) private returns (
        int128 oGLiq_,
        int128 nGLiq_,
        int128[] memory,
        int128[] memory
    ) {

        uint _length = shell.weights.length;
        int128[] memory oBals_ = new int128[](_length);
        int128[] memory nBals_ = new int128[](_length);

        for (uint i = 0; i < _derivatives.length; i++) {

            LoihiStorage.Assimilator memory _assim = shell.assimilators[_derivatives[i]];

            require(_assim.addr != address(0), "Shell/unsupported-derivative");

            if ( nBals_[_assim.ix] == 0 && oBals_[_assim.ix] == 0 ) {

                ( int128 _amount, int128 _balance ) = Assimilators.outputRawAndGetBalance(_assim.addr, _rcpnt, _amounts[i]);

                nBals_[_assim.ix] = _balance;
                oBals_[_assim.ix] = _balance.sub(_amount);

            } else {

                int128 _amount = Assimilators.outputRaw(_assim.addr, _rcpnt, _amounts[i]);

                nBals_[_assim.ix] = nBals_[_assim.ix].sub(_amount);

            }

        }

        return completeLiquidityData(shell, oBals_, nBals_);

    }

    function viewLiquidityDepositData (
        LoihiStorage.Shell storage shell,
        address[] memory _derivatives,
        uint[] memory _amounts
    ) private view returns (
        int128 oGLiq_,
        int128 nGLiq_,
        int128[] memory,
        int128[] memory
    ) {

        uint _length = shell.assets.length;
        int128[] memory oBals_ = new int128[](_length);
        int128[] memory nBals_ = new int128[](_length);

        for (uint i = 0; i < _derivatives.length; i++) {

            LoihiStorage.Assimilator memory _assim = shell.assimilators[_derivatives[i]];

            require(_assim.addr != address(0), "Shell/unsupported-derivative");

            if ( nBals_[_assim.ix] == 0 && oBals_[_assim.ix] == 0 ) {

                ( int128 _amount, int128 _balance ) = Assimilators.viewNumeraireAmountAndBalance(_assim.addr, _amounts[i]);

                nBals_[_assim.ix] = _balance.add(_amount);

                oBals_[_assim.ix] = _balance;

            } else {

                int128 _amount = Assimilators.viewNumeraireAmount(_assim.addr, _amounts[i]);

                nBals_[_assim.ix] = nBals_[_assim.ix].sub(_amount);

            }

        }

        return completeLiquidityData(shell, oBals_, nBals_);

    }

    function viewLiquidityWithdrawData (
        LoihiStorage.Shell storage shell,
        address[] memory _derivatives,
        uint[] memory _amounts
    ) private view returns (
        int128 oGLiq_,
        int128 nGLiq_,
        int128[] memory,
        int128[] memory
    ) {

        uint _length = shell.assets.length;
        int128[] memory oBals_ = new int128[](_length);
        int128[] memory nBals_ = new int128[](_length);

        for (uint i = 0; i < _derivatives.length; i++) {

            LoihiStorage.Assimilator memory _assim = shell.assimilators[_derivatives[i]];

            require(_assim.addr != address(0), "Shell/unsupported-derivative");

            if ( nBals_[_assim.ix] == 0 && oBals_[_assim.ix] == 0 ) {

                ( int128 _amount, int128 _balance ) = Assimilators.viewNumeraireAmountAndBalance(_assim.addr, _amounts[i]);

                nBals_[_assim.ix] = _balance.add(_amount.neg());

                oBals_[_assim.ix] = _balance;

            } else {

                int128 _amount = Assimilators.viewNumeraireAmount(_assim.addr, _amounts[i]);

                nBals_[_assim.ix] = nBals_[_assim.ix].sub(_amount.neg());

            }

        }

        return completeLiquidityData(shell, oBals_, nBals_);

    }

    function completeLiquidityData (
        LoihiStorage.Shell storage shell,
        int128[] memory oBals_,
        int128[] memory nBals_
    ) private view returns (
        int128 oGLiq_,
        int128 nGLiq_,
        int128[] memory,
        int128[] memory
    ) {

        uint _length = oBals_.length;

        for (uint i = 0; i < _length; i++) {

            if (oBals_[i] == 0 && nBals_[i] == 0) nBals_[i] = oBals_[i] = Assimilators.viewNumeraireBalance(shell.assets[i].addr);

            oGLiq_ += oBals_[i];
            nGLiq_ += nBals_[i];

        }

        return ( oGLiq_, nGLiq_, oBals_, nBals_ );

    }

    function burn (LoihiStorage.Shell storage shell, address account, uint256 amount) private {

        shell.balances[account] = burn_sub(shell.balances[account], amount);

        shell.totalSupply = burn_sub(shell.totalSupply, amount);

        emit Transfer(msg.sender, address(0), amount);

    }

    function mint (LoihiStorage.Shell storage shell, address account, uint256 amount) private {

        shell.totalSupply = mint_add(shell.totalSupply, amount);

        shell.balances[account] = mint_add(shell.balances[account], amount);

        emit Transfer(address(0), msg.sender, amount);

    }

    function mint_add(uint x, uint y) private pure returns (uint z) {
        require((z = x + y) >= x, "Shell/mint-overflow");
    }

    function burn_sub(uint x, uint y) private pure returns (uint z) {
        require((z = x - y) <= x, "Shell/burn-underflow");
    }

}


library Assimilators {

    using ABDKMath64x64 for int128;
    IAssimilator constant iAsmltr = IAssimilator(address(0));

    function delegate(address _callee, bytes memory _data) internal returns (bytes memory) {

        (bool _success, bytes memory returnData_) = _callee.delegatecall(_data);

        assembly { if eq(_success, 0) { revert(add(returnData_, 0x20), returndatasize()) } }

        return returnData_;

    }

    function viewRawAmount (address _assim, int128 _amt) internal view returns (uint256 amount_) {

        amount_ = IAssimilator(_assim).viewRawAmount(_amt);

    }

    function viewNumeraireAmount (address _assim, uint256 _amt) internal view returns (int128 amt_) {

        amt_ = IAssimilator(_assim).viewNumeraireAmount(_amt);

    }

    function viewNumeraireAmountAndBalance (address _assim, uint256 _amt) internal view returns (int128 amt_, int128 bal_) {

        ( amt_, bal_ ) = IAssimilator(_assim).viewNumeraireAmountAndBalance(address(this), _amt);

    }

    function viewNumeraireBalance (address _assim) internal view returns (int128 bal_) {

        bal_ = IAssimilator(_assim).viewNumeraireBalance(address(this));

    }

    function intakeRaw (address _assim, uint256 _amount) internal returns (int128 amt_) {

        bytes memory data = abi.encodeWithSelector(iAsmltr.intakeRaw.selector, _amount);

        amt_ = abi.decode(delegate(_assim, data), (int128));

    }

    function intakeRawAndGetBalance (address _assim, uint256 _amount) internal returns (int128 amt_, int128 bal_) {

        bytes memory data = abi.encodeWithSelector(iAsmltr.intakeRawAndGetBalance.selector, _amount);

        ( amt_, bal_ ) = abi.decode(delegate(_assim, data), (int128,int128));

    }

    function intakeNumeraire (address _assim, int128 _amt) internal returns (uint256 rawAmt_) {

        bytes memory data = abi.encodeWithSelector(iAsmltr.intakeNumeraire.selector, _amt);

        rawAmt_ = abi.decode(delegate(_assim, data), (uint256));

    }

    function outputRaw (address _assim, address _dst, uint256 _amount) internal returns (int128 amt_ ) {

        bytes memory data = abi.encodeWithSelector(iAsmltr.outputRaw.selector, _dst, _amount);

        amt_ = abi.decode(delegate(_assim, data), (int128));

        amt_ = amt_.neg();

    }

    function outputRawAndGetBalance (address _assim, address _dst, uint256 _amount) internal returns (int128 amt_, int128 bal_) {

        bytes memory data = abi.encodeWithSelector(iAsmltr.outputRawAndGetBalance.selector, _dst, _amount);

        ( amt_, bal_ ) = abi.decode(delegate(_assim, data), (int128,int128));

        amt_ = amt_.neg();

    }

    function outputNumeraire (address _assim, address _dst, int128 _amt) internal returns (uint256 rawAmt_) {

        bytes memory data = abi.encodeWithSelector(iAsmltr.outputNumeraire.selector, _dst, _amt.abs());

        rawAmt_ = abi.decode(delegate(_assim, data), (uint256));

    }
}

contract LoihiStorage {

    string  public constant name = "Shells";
    string  public constant symbol = "SHL";
    uint8   public constant decimals = 18;

    struct Shell {
        int128 alpha;
        int128 beta;
        int128 delta;
        int128 epsilon;
        int128 lambda;
        int128 omega;
        int128[] weights;
        uint totalSupply;
        mapping (address => uint) balances;
        mapping (address => mapping (address => uint)) allowances;
        Assimilator[] assets;
        mapping (address => Assimilator) assimilators;
    }

    struct Assimilator {
        address addr;
        uint8 ix;
    }

    Shell public shell;

    struct PartitionTicket {
        uint[] claims;
        bool initialized;
    }

    mapping (address => PartitionTicket) public partitionTickets;

    address[] public derivatives;
    address[] public numeraires;
    address[] public reserves;

    bool public partitioned = false;
    bool public frozen = false;

    address public owner;
    bool internal notEntered = true;

    uint public maxFee;

}


library ShellMath {

    int128 constant ONE = 0x10000000000000000;
    int128 constant MAX = 0x4000000000000000; // .25 in laments terms
    int128 constant ONE_WEI = 0x12;

    using ABDKMath64x64 for int128;
    using UnsafeMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    function calculateFee (
        int128 _gLiq,
        int128[] memory _bals,
        int128 _beta,
        int128 _delta,
        int128[] memory _weights
    ) internal pure returns (int128 psi_) {

        for (uint i = 0; i < _weights.length; i++) {
            int128 _ideal = _gLiq.us_mul(_weights[i]);
            psi_ += calculateMicroFee(_bals[i], _ideal, _beta, _delta);
        }

    }

    function calculateMicroFee (
        int128 _bal,
        int128 _ideal,
        int128 _beta,
        int128 _delta
    ) private pure returns (int128 fee_) {

        if (_bal < _ideal) {

            int128 _threshold = _ideal.us_mul(ONE - _beta);

            if (_bal < _threshold) {

                int128 _feeSection = _threshold - _bal;

                fee_ = _feeSection.us_div(_ideal);
                fee_ = fee_.us_mul(_delta);

                if (fee_ > MAX) fee_ = MAX;

                fee_ = fee_.us_mul(_feeSection);

            } else fee_ = 0;

        } else {

            int128 _threshold = _ideal.us_mul(ONE + _beta);

            if (_bal > _threshold) {

                int128 _feeSection = _bal - _threshold;

                fee_ = _feeSection.us_div(_ideal);
                fee_ = fee_.us_mul(_delta);

                if (fee_ > MAX) fee_ = MAX;

                fee_ = fee_.us_mul(_feeSection);

            } else fee_ = 0;

        }

    }

    function calculateTrade (
        LoihiStorage.Shell storage shell,
        int128 _oGLiq,
        int128 _nGLiq,
        int128[] memory _oBals,
        int128[] memory _nBals,
        int128 _inputAmt,
        uint _outputIndex
    ) internal view returns (int128 outputAmt_ , int128 psi_) {

        outputAmt_ = - _inputAmt;

        int128 _lambda = shell.lambda;
        int128 _omega = shell.omega;
        int128 _beta = shell.beta;
        int128 _delta = shell.delta;
        int128[] memory _weights = shell.weights;

        for (uint i = 0; i < 32; i++) {

            psi_ = calculateFee(_nGLiq, _nBals, _beta, _delta, _weights);

            if (( outputAmt_ = _omega < psi_
                    ? - ( _inputAmt + _omega - psi_ )
                    : - ( _inputAmt + _lambda.us_mul(_omega - psi_))
                ) / 1e13 == outputAmt_ / 1e13 ) {

                _nGLiq = _oGLiq + _inputAmt + outputAmt_;

                _nBals[_outputIndex] = _oBals[_outputIndex] + outputAmt_;

                enforceHalts(shell, _oGLiq, _nGLiq, _oBals, _nBals, _weights);

                require(ABDKMath64x64.sub(_oGLiq, _omega) <= ABDKMath64x64.sub(_nGLiq, psi_), "Shell/swap-invariant-violation");

                return ( outputAmt_, psi_ );

            } else {

                _nGLiq = _oGLiq + _inputAmt + outputAmt_;

                _nBals[_outputIndex] = _oBals[_outputIndex].add(outputAmt_);

            }

        }

        revert("Shell/swap-convergence-failed");

    }

    function calculateLiquidityMembrane (
        LoihiStorage.Shell storage shell,
        int128 _oGLiq,
        int128 _nGLiq,
        int128[] memory _oBals,
        int128[] memory _nBals
    ) internal view returns (int128 shells_, int128 psi_) {

        enforceHalts(shell, _oGLiq, _nGLiq, _oBals, _nBals, shell.weights);

        psi_ = calculateFee(_nGLiq, _nBals, shell.beta, shell.delta, shell.weights);

        int128 _omega = shell.omega;
        int128 _feeDiff = psi_.sub(_omega);
        int128 _liqDiff = _nGLiq.sub(_oGLiq);
        int128 _oUtil = _oGLiq.sub(_omega);
        uint _totalSupply = shell.totalSupply;

        if (_totalSupply == 0) {

            shells_ = _nGLiq.sub(psi_);

        } else if (_feeDiff >= 0) {

            shells_ = _liqDiff.sub(_feeDiff).div(_oUtil);

        } else {
            
            shells_ = _liqDiff.sub(shell.lambda.mul(_feeDiff));
            
            shells_ = shells_.div(_oUtil);

        }

        int128 _shellsPrev = _totalSupply.divu(1e18);

        if (_totalSupply != 0) {

            shells_ = shells_.mul(_shellsPrev);

            int128 _prevUtilPerShell = _oGLiq.sub(_omega);
            
            _prevUtilPerShell = _prevUtilPerShell.div(_shellsPrev);

            int128 _nextUtilPerShell = _nGLiq.sub(psi_);
            
            _nextUtilPerShell = _nextUtilPerShell.div(_shellsPrev.add(shells_));

            _nextUtilPerShell += ONE_WEI;

            require(_prevUtilPerShell <= _nextUtilPerShell, "Shell/invariant-violation");

        }

    }

    function enforceHalts (
        LoihiStorage.Shell storage shell,
        int128 _oGLiq,
        int128 _nGLiq,
        int128[] memory _oBals,
        int128[] memory _nBals,
        int128[] memory _weights
    ) private view {

        uint256 _length = _nBals.length;
        int128 _alpha = shell.alpha;

        for (uint i = 0; i < _length; i++) {

            int128 _nIdeal = _nGLiq.us_mul(_weights[i]);

            if (_nBals[i] > _nIdeal) {

                int128 _upperAlpha = ONE + _alpha;

                int128 _nHalt = _nIdeal.us_mul(_upperAlpha);

                if (_nBals[i] > _nHalt){

                    int128 _oHalt = _oGLiq.us_mul(_weights[i]).us_mul(_upperAlpha);

                    if (_oBals[i] < _oHalt) revert("Shell/upper-halt");
                    if (_nBals[i] - _nHalt > _oBals[i] - _oHalt) revert("Shell/upper-halt");

                }

            } else {

                int128 _lowerAlpha = ONE - _alpha;

                int128 _nHalt = _nIdeal.us_mul(_lowerAlpha);

                if (_nBals[i] < _nHalt){

                    int128 _oHalt = _oGLiq.us_mul(_weights[i]).us_mul(_lowerAlpha);

                    if (_oBals[i] > _oHalt) revert("Shell/lower-halt");
                    if (_nHalt - _nBals[i] > _oHalt - _oBals[i]) revert("Shel/lower-halt");

                }
            }
        }

    }

}

library UnsafeMath64x64 {

  /**
   * Calculate x * y rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */

  function us_mul (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) * y >> 64;
    return int128 (result);
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */

  function us_div (int128 x, int128 y) internal pure returns (int128) {
    int256 result = (int256 (x) << 64) / y;
    return int128 (result);
  }

}

library ABDKMath64x64 {
  /**
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /**
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    return int64 (x >> 64);
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    require (x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    require (x >= 0);
    return uint64 (x >> 64);
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    int256 result = x >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    return int256 (x) << 64;
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) + y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) - y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) * y >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    if (x == MIN_64x64) {
      require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
        y <= 0x1000000000000000000000000000000000000000000000000);
      return -y << 63;
    } else {
      bool negativeResult = false;
      if (x < 0) {
        x = -x;
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint256 absoluteResult = mulu (x, uint256 (y));
      if (negativeResult) {
        require (absoluteResult <=
          0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <=
          0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (absoluteResult);
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    if (y == 0) return 0;

    require (x >= 0);

    uint256 lo = (uint256 (x) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
    uint256 hi = uint256 (x) * (y >> 128);

    require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    hi <<= 64;

    require (hi <=
      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
    return hi + lo;
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    require (y != 0);
    int256 result = (int256 (x) << 64) / y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    require (y != 0);

    bool negativeResult = false;
    if (x < 0) {
      x = -x; // We rely on overflow behavior here
      negativeResult = true;
    }
    if (y < 0) {
      y = -y; // We rely on overflow behavior here
      negativeResult = !negativeResult;
    }
    uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); // We rely on overflow behavior here
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    require (y != 0);
    uint128 result = divuu (x, y);
    require (result <= uint128 (MAX_64x64));
    return int128 (result);
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return -x;
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return x < 0 ? -x : x;
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    require (x != 0);
    int256 result = int256 (0x100000000000000000000000000000000) / x;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    return int128 ((int256 (x) + int256 (y)) >> 1);
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    int256 m = int256 (x) * int256 (y);
    require (m >= 0);
    require (m <
        0x4000000000000000000000000000000000000000000000000000000000000000);
    return int128 (sqrtu (uint256 (m), uint256 (x) + uint256 (y) >> 1));
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    uint256 absoluteResult;
    bool negativeResult = false;
    if (x >= 0) {
      absoluteResult = powu (uint256 (x) << 63, y);
    } else {
      // We rely on overflow behavior here
      absoluteResult = powu (uint256 (uint128 (-x)) << 63, y);
      negativeResult = y & 1 > 0;
    }

    absoluteResult >>= 63;

    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); // We rely on overflow behavior here
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    require (x >= 0);
    return int128 (sqrtu (uint256 (x) << 64, 0x10000000000000000));
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    require (x > 0);

    int256 msb = 0;
    int256 xc = x;
    if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
    if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
    if (xc >= 0x10000) { xc >>= 16; msb += 16; }
    if (xc >= 0x100) { xc >>= 8; msb += 8; }
    if (xc >= 0x10) { xc >>= 4; msb += 4; }
    if (xc >= 0x4) { xc >>= 2; msb += 2; }
    if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

    int256 result = msb - 64 << 64;
    uint256 ux = uint256 (x) << 127 - msb;
    for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
      ux *= ux;
      uint256 b = ux >> 255;
      ux >>= 127 + b;
      result += bit * int256 (b);
    }

    return int128 (result);
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    require (x > 0);

    return int128 (
        uint256 (log_2 (x)) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128);
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    uint256 result = 0x80000000000000000000000000000000;

    if (x & 0x8000000000000000 > 0)
      result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
    if (x & 0x4000000000000000 > 0)
      result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
    if (x & 0x2000000000000000 > 0)
      result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
    if (x & 0x1000000000000000 > 0)
      result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
    if (x & 0x800000000000000 > 0)
      result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
    if (x & 0x400000000000000 > 0)
      result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
    if (x & 0x200000000000000 > 0)
      result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
    if (x & 0x100000000000000 > 0)
      result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
    if (x & 0x80000000000000 > 0)
      result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
    if (x & 0x40000000000000 > 0)
      result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
    if (x & 0x20000000000000 > 0)
      result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
    if (x & 0x10000000000000 > 0)
      result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
    if (x & 0x8000000000000 > 0)
      result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
    if (x & 0x4000000000000 > 0)
      result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
    if (x & 0x2000000000000 > 0)
      result = result * 0x1000162E525EE054754457D5995292026 >> 128;
    if (x & 0x1000000000000 > 0)
      result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
    if (x & 0x800000000000 > 0)
      result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
    if (x & 0x400000000000 > 0)
      result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
    if (x & 0x200000000000 > 0)
      result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
    if (x & 0x100000000000 > 0)
      result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
    if (x & 0x80000000000 > 0)
      result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
    if (x & 0x40000000000 > 0)
      result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
    if (x & 0x20000000000 > 0)
      result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
    if (x & 0x10000000000 > 0)
      result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
    if (x & 0x8000000000 > 0)
      result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
    if (x & 0x4000000000 > 0)
      result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
    if (x & 0x2000000000 > 0)
      result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
    if (x & 0x1000000000 > 0)
      result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
    if (x & 0x800000000 > 0)
      result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
    if (x & 0x400000000 > 0)
      result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
    if (x & 0x200000000 > 0)
      result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
    if (x & 0x100000000 > 0)
      result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
    if (x & 0x80000000 > 0)
      result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
    if (x & 0x40000000 > 0)
      result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
    if (x & 0x20000000 > 0)
      result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
    if (x & 0x10000000 > 0)
      result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
    if (x & 0x8000000 > 0)
      result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
    if (x & 0x4000000 > 0)
      result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
    if (x & 0x2000000 > 0)
      result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
    if (x & 0x1000000 > 0)
      result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
    if (x & 0x800000 > 0)
      result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
    if (x & 0x400000 > 0)
      result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
    if (x & 0x200000 > 0)
      result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
    if (x & 0x100000 > 0)
      result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
    if (x & 0x80000 > 0)
      result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
    if (x & 0x40000 > 0)
      result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
    if (x & 0x20000 > 0)
      result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
    if (x & 0x10000 > 0)
      result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
    if (x & 0x8000 > 0)
      result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
    if (x & 0x4000 > 0)
      result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
    if (x & 0x2000 > 0)
      result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
    if (x & 0x1000 > 0)
      result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
    if (x & 0x800 > 0)
      result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
    if (x & 0x400 > 0)
      result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
    if (x & 0x200 > 0)
      result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
    if (x & 0x100 > 0)
      result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
    if (x & 0x80 > 0)
      result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
    if (x & 0x40 > 0)
      result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
    if (x & 0x20 > 0)
      result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
    if (x & 0x10 > 0)
      result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
    if (x & 0x8 > 0)
      result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
    if (x & 0x4 > 0)
      result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
    if (x & 0x2 > 0)
      result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
    if (x & 0x1 > 0)
      result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

    result >>= 63 - (x >> 64);
    require (result <= uint256 (MAX_64x64));

    return int128 (result);
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    return exp_2 (
        int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    require (y != 0);

    uint256 result;

    if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      result = (x << 64) / y;
    else {
      uint256 msb = 192;
      uint256 xc = x >> 192;
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 hi = result * (y >> 128);
      uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 xh = x >> 192;
      uint256 xl = x << 64;

      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here
      lo = hi << 128;
      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here

      assert (xh == hi >> 128);

      result += xl / y;
    }

    require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    return uint128 (result);
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is unsigned 129.127 fixed point
   * number and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x unsigned 129.127-bit fixed point number
   * @param y uint256 value
   * @return unsigned 129.127-bit fixed point number
   */
  function powu (uint256 x, uint256 y) private pure returns (uint256) {
    if (y == 0) return 0x80000000000000000000000000000000;
    else if (x == 0) return 0;
    else {
      int256 msb = 0;
      uint256 xc = x;
      if (xc >= 0x100000000000000000000000000000000) { xc >>= 128; msb += 128; }
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 xe = msb - 127;
      if (xe > 0) x >>= xe;
      else x <<= -xe;

      uint256 result = 0x80000000000000000000000000000000;
      int256 re = 0;

      while (y > 0) {
        if (y & 1 > 0) {
          result = result * x;
          y -= 1;
          re += xe;
          if (result >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            result >>= 128;
            re += 1;
          } else result >>= 127;
          if (re < -127) return 0; // Underflow
          require (re < 128); // Overflow
        } else {
          x = x * x;
          y >>= 1;
          xe <<= 1;
          if (x >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            x >>= 128;
            xe += 1;
          } else x >>= 127;
          if (xe < -127) return 0; // Underflow
          require (xe < 128); // Overflow
        }
      }

      if (re > 0) result <<= re;
      else if (re < 0) result >>= -re;

      return result;
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x, uint256 r) private pure returns (uint128) {
    if (x == 0) return 0;
    else {
      require (r > 0);
      while (true) {
        uint256 rr = x / r;
        if (r == rr || r + 1 == rr) return uint128 (r);
        else if (r == rr + 1) return uint128 (rr);
        r = r + rr + 1 >> 1;
      }
    }
  }
}


interface IAssimilator {
    function intakeRaw (uint256 amount) external returns (int128);
    function intakeRawAndGetBalance (uint256 amount) external returns (int128, int128);
    function intakeNumeraire (int128 amount) external returns (uint256);
    function outputRaw (address dst, uint256 amount) external returns (int128);
    function outputRawAndGetBalance (address dst, uint256 amount) external returns (int128, int128);
    function outputNumeraire (address dst, int128 amount) external returns (uint256);
    function viewRawAmount (int128) external view returns (uint256);
    function viewNumeraireAmount (uint256) external view returns (int128);
    function viewNumeraireBalance (address) external view returns (int128);
    function viewNumeraireAmountAndBalance (address, uint256) external view returns (int128, int128);
}