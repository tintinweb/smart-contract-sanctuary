/**
 *Submitted for verification at FtmScan.com on 2022-01-23
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function add32(uint32 x, uint32 y) internal pure returns (uint32 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function sub32(uint32 x, uint32 y) internal pure returns (uint32 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    function mul32(uint32 x, uint32 y) internal pure returns (uint32 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0));
    }

    function div(uint256 x, uint256 y) internal pure returns(uint256 z){
        require(y > 0);
        z=x/y;
    }
}

library Address {

  function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function functionCall(
        address target, 
        bytes memory data, 
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function _functionCallWithValue(
        address target, 
        bytes memory data, 
        uint256 weiValue, 
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function _verifyCallResult(
        bool success, 
        bytes memory returndata, 
        string memory errorMessage
    ) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract OwnableData {
    address public owner;
    address public pendingOwner;
}

contract Ownable is OwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using LowGasSafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IERC20Mintable {
  function mint (uint256 amount_) external;

  function mint (address account_, uint256 amount_) external;
}

interface INox is IERC20 {
    function unstableAmount (address who) external view returns (uint256);
}

interface ICyber is IERC20Mintable, IERC20 {
    function burnFrom (address account_, uint256 amount_) external;
}

interface IExtractorCalculator {
  function valuation (address pair_, uint amount_) external view returns (uint _value);
}

contract CyberTreasury is Ownable {

    using LowGasSafeMath for uint;
    using LowGasSafeMath for uint32;
    using SafeERC20 for IERC20;

    event Deposit (address indexed token, uint amount, uint value);
    event Withdrawal (address indexed token, uint amount, uint value);
    event CreateDebt (address indexed debtor, address indexed token, uint amount, uint value);
    event RepayDebt (address indexed debtor, address indexed token, uint amount, uint value);
    event ReservesManaged (address indexed token, uint amount);
    event ReservesUpdated (uint indexed totalReserves);
    event ReservesAudited (uint indexed totalReserves);
    event RewardsMinted (address indexed caller, address indexed recipient, uint amount);
    event Toggle (MANAGING indexed managing, address activated, bool result);
    event ChangeLimitAmount (uint256 amount);

    enum MANAGING { 
        RESERVE_DEPOSITOR,
        RESERVE_SPENDER,
        RESERVE_TOKEN,
        RESERVE_MANAGER,
        LIQUIDITY_DEPOSITOR,
        LIQUIDITY_TOKEN,
        LIQUIDITY_MANAGER,
        DEBTOR,
        REWARD_MANAGER,
        NOX
    }

    ICyber public immutable Cyber;
    address public DAO;

    address[] public reserveTokens;
    mapping (address => bool) public isReserveToken;

    address[] public reserveDepositors;
    mapping (address => bool) public isReserveDepositor;

    address[] public reserveSpenders;
    mapping (address => bool) public isReserveSpender;

    address[] public liquidityTokens;
    mapping (address => bool) public isLiquidityToken;

    address[] public liquidityDepositors;
    mapping (address => bool) public isLiquidityDepositor;

    mapping (address => address) public extractorCalculator;

    address[] public reserveManagers;
    mapping (address => bool) public isReserveManager;

    address[] public liquidityManagers;
    mapping (address => bool) public isLiquidityManager;

    address[] public debtors;
    mapping (address => bool) public isDebtor;
    mapping (address => uint) public debtorBalance;

    address[] public rewardManagers;
    mapping (address => bool) public isRewardManager;

    INox public Nox;

    uint public totalReserves;
    uint public totalDebt;

    constructor (address _Cyber, address _Frax, address _DAO) {
        require(_Cyber != address(0));
        Cyber = ICyber(_Cyber);
        require(_Frax != address(0));
        isReserveToken[_Frax] = true;
        reserveTokens.push(_Frax);
        require(_DAO != address(0));
        DAO = _DAO;
    }

    /**
        @notice allow approved address to deposit an asset for Cyber
        @param _amount uint
        @param _token address
        @param _profit uint
        @return send_ uint
     */
    function deposit (uint _amount, address _token, uint _profit) external returns (uint send_) {
        require(isReserveToken[_token] || isLiquidityToken[_token], "Not accepted");
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        if (isReserveToken[_token]) {
            require(isReserveDepositor[msg.sender], "Not approved");
        } else {
            require(isLiquidityDepositor[msg.sender], "Not approved");
        }

        uint value = cyberValueOf(_token, _amount);
        send_ = value.sub(_profit);
        Cyber.mint(msg.sender, send_);

        totalReserves = totalReserves.add(value);
        emit ReservesUpdated(totalReserves);

        emit Deposit(_token, _amount, value);
    }

    /**
        @notice allow approved address to burn Cyber for reserves
        @param _amount uint
        @param _token address
     */
    function withdraw (uint _amount, address _token) external {
        require(isReserveToken[_token], "Not accepted");
        require(isReserveSpender[msg.sender], "Not approved");

        uint value = cyberValueOf(_token, _amount);
        Cyber.burnFrom(msg.sender, value);

        totalReserves = totalReserves.sub(value);
        emit ReservesUpdated(totalReserves);

        IERC20(_token).safeTransfer(msg.sender, _amount);

        emit Withdrawal(_token, _amount, value);
    }

    /**
     *  @notice update DAO address
     *  @param _DAO address
     */
    function setDAOAddress (address _DAO) external onlyOwner {
        require(_DAO != address(0));
        DAO = _DAO;
    }

    /**
        @notice allow the DAO to withdraw assets without impacting excess reserves,
                in order to deploy them in various strategies
        @param _token address
        @param _amount uint
     */
    function manage (address _token, uint _amount) external {
        require(msg.sender == DAO, "Unauthorized");
        require(isLiquidityToken[_token] || isReserveToken[_token], "Invalid address");
        if (isLiquidityToken[_token]) {
            require(isLiquidityManager[msg.sender], "Not approved");
        } else {
            require(isReserveManager[msg.sender], "Not approved");
        }

        IERC20(_token).safeTransfer(msg.sender, _amount);
        emit ReservesManaged(_token, _amount);
    }

    /**
        @notice send epoch reward to reactor
     */
    function mintRewards (address _recipient, uint _amount) external {
        require(isRewardManager[msg.sender], "Not approved");
        if (_amount > excessReserves()) {
            _amount = excessReserves();
        }
        Cyber.mint(_recipient, _amount);

        emit RewardsMinted(msg.sender, _recipient, _amount);
    } 

    /**
        @notice returns excess reserves not backing tokens
        @return uint
     */
    function excessReserves () public view returns (uint) {
        return totalReserves.sub(Cyber.totalSupply().sub(totalDebt));
    }

    /**
        @notice takes inventory of all tracked assets
        @notice always consolidate to recognized reserves before audit
     */
    function auditReserves () external onlyOwner {
        uint reserves;
        for (uint k = 0; k < reserveTokens.length; k++) {
            reserves = reserves.add(cyberValueOf(reserveTokens[k], IERC20(reserveTokens[k]).balanceOf(address(this))));
        }

        for (uint k = 0; k < liquidityTokens.length; k++) {
            reserves = reserves.add(cyberValueOf(liquidityTokens[k], IERC20(liquidityTokens[k]).balanceOf(address(this))));
        }

        totalReserves = reserves;
        emit ReservesUpdated(reserves);
        emit ReservesAudited(reserves);
    }

    /**
        @notice returns Cyber valuation of asset
        @param _token address
        @param _amount uint
        @return value_ uint
     */
    function cyberValueOf (address _token, uint _amount) public view returns (uint value_) {
        if (isReserveToken[_token]) {
            value_ = _amount.mul(10 ** Cyber.decimals()).div(10 ** IERC20(_token).decimals());
        } else if (isLiquidityToken[_token]) {
            value_ = IExtractorCalculator(extractorCalculator[_token]).valuation(_token, _amount);
        }
    }

    /**
        @notice set boolean in mapping
        @param _managing MANAGING
        @param _address address
        @param _calculator address
        @return bool
     */
    function toggle (MANAGING _managing, address _address, address _calculator) external onlyOwner returns (bool) {
        require(_address != address(0), "Invalid address");

        bool result;
        if (_managing == MANAGING.RESERVE_DEPOSITOR) {
            if (!listContains(reserveDepositors, _address)) {
                reserveDepositors.push(_address);
            }

            result = !isReserveDepositor[_address];
            isReserveDepositor[_address] = result;
        } else if (_managing == MANAGING.RESERVE_SPENDER) {
            if (!listContains(reserveSpenders, _address)) {
                reserveSpenders.push(_address);
            }

            result = !isReserveSpender[_address];
            isReserveSpender[_address] = result;
        } else if (_managing == MANAGING.RESERVE_TOKEN) {
            if (!listContains(reserveTokens, _address) && !listContains(liquidityTokens, _address)) {
                reserveTokens.push( _address );
            }

            result = !isReserveToken[_address];
            require(!result || !isLiquidityToken[_address], "Do not add to both types of token");
            isReserveToken[_address] = result;
        } else if (_managing == MANAGING.RESERVE_MANAGER) {
            reserveManagers.push(_address);
            if (!listContains(reserveManagers, _address)) {
                reserveManagers.push(_address);
            }

            result = !isReserveManager[_address];
            isReserveManager[_address] = result;
        } else if (_managing == MANAGING.LIQUIDITY_DEPOSITOR ) {
            liquidityDepositors.push(_address);
            if (!listContains(liquidityDepositors, _address)) {
                liquidityDepositors.push(_address);
            }

            result = !isLiquidityDepositor[_address];
            isLiquidityDepositor[_address] = result;
        } else if (_managing == MANAGING.LIQUIDITY_TOKEN ) {
            require(_calculator != address(0), "Invalid address");
            if (!listContains(liquidityTokens, _address) && !listContains(reserveTokens, _address)) {
                liquidityTokens.push(_address);
            }

            result = !isLiquidityToken[_address];
            require(!result || !isReserveToken[_address], "Do not add to both types of token");
            isLiquidityToken[_address] = result;
            extractorCalculator[_address] = _calculator;
        } else if (_managing == MANAGING.LIQUIDITY_MANAGER) {
            if (!listContains(liquidityManagers, _address)) {
                liquidityManagers.push(_address);
            }

            result = !isLiquidityManager[_address];
            isLiquidityManager[_address] = result;
        } else if (_managing == MANAGING.DEBTOR) {
            if (!listContains( debtors, _address)) {
                debtors.push(_address);
            }

            result = !isDebtor[_address];
            isDebtor[_address] = result;
        } else if (_managing == MANAGING.REWARD_MANAGER) {
            if (!listContains( rewardManagers, _address)) {
                rewardManagers.push(_address);
            }

            result = !isRewardManager[_address];
            isRewardManager[_address] = result;
        } else if (_managing == MANAGING.NOX) {
            Nox = INox(_address);
            result = true;
        } else {
            return false;
        }

        emit Toggle(_managing, _address, result);
        return true;
    }

    /**
        @notice checks array to ensure against duplicate
        @param _list address[]
        @param _token address
        @return bool
     */
    function listContains (address[] storage _list, address _token) internal view returns (bool) {
        for (uint k = 0; k < _list.length; k++) {
            if (_list[k] == _token) {
                return true;
            }
        }

        return false;
    }
}