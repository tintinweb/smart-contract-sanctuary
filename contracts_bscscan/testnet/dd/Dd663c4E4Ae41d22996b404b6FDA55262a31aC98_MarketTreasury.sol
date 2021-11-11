/**
 *Submitted for verification at BscScan.com on 2021-11-11
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract Lockable {
    bool private _notEntered;

    constructor() {
        _notEntered = true;
    }

    modifier nonReentrant() {
        _preEntranceCheck();
        _preEntranceSet();
        _;
        _postEntranceReset();
    }

    modifier nonReentrantView() {
        _preEntranceCheck();
        _;
    }

    function _preEntranceCheck() internal view {
        require(_notEntered, "ReentrancyGuard: reentrant call");
    }

    function _preEntranceSet() internal {
        _notEntered = false;
    }

    function _postEntranceReset() internal {
        _notEntered = true;
    }
}

interface ITreasury {
    function deposit( uint _amount, address _token, uint _profit ) external returns ( uint send_ );
}

interface IAlphaMarket {
    function totalFunds() external view returns (uint256);
    function mintTokens() external view returns (uint256);
}

interface IPublicMarket {
    function totalFunds() external view returns (uint256);
    function mintTokens() external view returns (uint256);
}

contract MarketTreasury is Ownable, Lockable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    ITreasury public treasury;
    IERC20 public GIZA;
    IERC20 public aGIZA;
    IERC20 public pGIZA;
    IERC20 public principle;

    address public alphaMigration;
    address public publicMigration;
    address public dao;

    uint256 public alphaMintTokens;
    uint256 public publicMintTokens;
    uint256 public daoRewardPercent = 10; // 10%

    IAlphaMarket public alphaMarket;
    IPublicMarket public publicMarket;
    uint256 public daoFundPercent = 30; // 30%
    uint256 public alphaFunds = 0; 
    uint256 public alphaTotalFunds = 0; 
    uint256 public publicFunds = 0; 
    uint256 public publicTotalFunds = 0; 
    uint256 public daoFunds = 0;

    bool public isInitialized;
    
    modifier onlyInitialized() {
        require(isInitialized, "not initialized");
        _;
    }
    
    modifier notInitialized() {
        require( !isInitialized, "already initialized" );
        _;
    }

    function initialize (
        address _aGIZA,
        address _pGIZA,
        address _principle,

        address _dao
    ) external onlyOwner() notInitialized() {
        aGIZA = IERC20(_aGIZA);
        pGIZA = IERC20(_pGIZA);
        principle = IERC20(_principle);
        dao = _dao;
        isInitialized = true;
    }

    function mintTokenForAlphaMigration() external onlyOwner() onlyInitialized() {
        require(alphaMigration != address(0), "alpha migration has not be seted");
        require(alphaFunds > 0, "alpha funds is zero");

        uint256 _value = alphaMintTokens;
        uint256 _funds = alphaFunds;
        _mintToken(alphaMigration, _funds, _value);
        alphaFunds = 0;
    }

    function mintTokenForPublicMigration() external onlyOwner() onlyInitialized() {
        require(publicMigration != address(0), "public migration has not be seted");
        require(publicFunds > 0, "public funds is zero");

        uint256 _value = publicMintTokens;
        uint256 _funds = publicFunds;
        _mintToken(publicMigration, _funds, _value);
        publicFunds = 0;
    }

    // @note: remember to add MarketTreasury as Treasury ReserveDepositor
    // auto mint daoRewardPercent tokens to dao, and the tokens will be locked in Treasury right now
    function _mintToken(address _recv, uint256 _funds, uint256 _value) private {
        require(address(GIZA) != address(0), "GIZA token has not be seted");
        require(address(treasury) != address(0), "treasury has not be seted");
        require(dao != address(0), "dao address is zero");

        uint256 _daoReward = _value.mul(daoRewardPercent).div(100);
        uint256 _newValue = _value.add(_daoReward);
        uint256 _totalValue = _funds.mul(10**GIZA.decimals()).div(10**principle.decimals());
        uint256 _profit = _totalValue.sub(_newValue);
        require(_profit > 0, "mint profit for treasury is zero");

        principle.safeApprove(address(treasury), _funds);
        treasury.deposit(_funds, address(principle), _profit);
        GIZA.safeTransfer(_recv, _value);
        GIZA.safeTransfer(dao, _daoReward);
    }

    function setAlphaMarket(address _alphaMarket) external onlyOwner() onlyInitialized() {
        require(address(alphaMarket) == address(0), "alpha market has seted");
        require(_alphaMarket != address(0), "input alpha market is zero");

        alphaMarket = IAlphaMarket(_alphaMarket);

        uint256 _alphaTotalFunds = alphaMarket.totalFunds();
        require(_alphaTotalFunds > 0, "alpha total funds is zero");
        
        alphaTotalFunds = _alphaTotalFunds;
        uint256 _fundsForDAOFromAlpha = _alphaTotalFunds.mul(daoFundPercent).div(100);
        alphaFunds = _alphaTotalFunds.sub(_fundsForDAOFromAlpha);
        daoFunds = daoFunds.add(_fundsForDAOFromAlpha);

        alphaMintTokens = alphaMarket.mintTokens();
    }

    
    function setPublicMarket(address _publicMarket) external onlyOwner() onlyInitialized() {
        require(address(publicMarket) == address(0), "public market has seted");
        require(_publicMarket != address(0), "input public market is zero");

        publicMarket = IPublicMarket(_publicMarket);

        uint256 _publicTotalFunds = publicMarket.totalFunds();
        require(_publicTotalFunds > 0, "public total funds is zero");

        publicTotalFunds = _publicTotalFunds;
        uint256 _fundsForDAOFromPublic = _publicTotalFunds.mul(daoFundPercent).div(100);
        publicFunds = _publicTotalFunds.sub(_fundsForDAOFromPublic);
        daoFunds = daoFunds.add(_fundsForDAOFromPublic);

        publicMintTokens = publicMarket.mintTokens();
    }

    function setAlphaMigration(address _alphaMigration) external onlyOwner() onlyInitialized() {
        require(alphaMigration == address(0), "alpha migration has seted");
        require(_alphaMigration != address(0), "input alpha migration is zero");

        alphaMigration = _alphaMigration;
    }

    
    function setPublicMigration(address _publicMigration) external onlyOwner() onlyInitialized() {
        require(publicMigration == address(0), "public migration has seted");
        require(_publicMigration != address(0), "input public migration is zero");

        publicMigration = _publicMigration;
    }

    function setToken(address _GIZA) external onlyOwner() onlyInitialized() {
        require(address(GIZA) == address(0), "GIZA token has seted");
        require(_GIZA != address(0), "input GIZA token is zero");

        GIZA = IERC20(_GIZA);
    }

    function setTreasury(address _treasury) external onlyOwner() onlyInitialized() {
        require(address(treasury) == address(0), "treasury token has seted");
        require(_treasury != address(0), "input treasury is zero");

        treasury = ITreasury(_treasury);
    }

    function setDAO(address _dao) external onlyOwner() {
        require(_dao != address(0), "dao address is zero");

        dao = _dao;
    }
    
    // dao will only reclaim the reward funds
    function reclaimDAOFunds(uint256 _amount) external onlyOwner() onlyInitialized() {
        require(daoFunds > _amount, "amount above the dao funds");
        require(principle.balanceOf(address(this)) > _amount, "amount above treasury balance");
        require(dao != address(0), "dao address is zero");

        principle.safeTransfer(dao, _amount);
        daoFunds = daoFunds.sub(_amount);
    }

    // the extra aTokne and pToken will be reclaim by dao and then burn
    function burnTokens() external onlyOwner() onlyInitialized() {
        uint256 _aBalance = aGIZA.balanceOf(address(this));
        uint256 _pBalance = pGIZA.balanceOf(address(this));
        require(dao != address(0), "dao address is zero");

        aGIZA.safeTransfer(dao, _aBalance);
        pGIZA.safeTransfer(dao, _pBalance);
    }

    // The _recv and _amount can be voted by community
    function reclaimTokens(address _recv, uint256 _amount) external onlyOwner() onlyInitialized() {
        require(_recv != address(0), "recv address is zero");

        uint256 _balance = GIZA.balanceOf(address(this));
        require(_balance > _amount, "reclaim amount over balance");

        GIZA.safeTransfer(_recv, _amount);
    }
}