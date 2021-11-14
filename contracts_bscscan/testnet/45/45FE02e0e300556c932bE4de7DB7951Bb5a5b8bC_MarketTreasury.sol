/**
 *Submitted for verification at BscScan.com on 2021-11-13
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
}

contract MarketTreasury is Ownable, Lockable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    ITreasury public treasury;
    IERC20 public GIZA;
    IERC20 public aToken;
    IERC20 public pToken;
    IERC20 public principle;

    address public alphaMigration;
    address public publicMigration;
    IAlphaMarket public alphaMarket;
    IPublicMarket public publicMarket;

    address public dao;
    uint256 public daoRewardPercent = 10; // 10%
    uint256 public daoFundPercent = 25; // 25%
    uint256 public reclaimedDAOFunds = 0;
    uint256 public spendedAlphaFunds = 0;
    uint256 public spendedPublicFunds = 0;

    bool public isInitialized;

    event Initialize(
        address _aToken,
        address _pToken,
        address _principle,
        address _alphaMarket,
        address _publicMarket,
        address _dao
    );
    event MintTokens(
        address _recv, 
        address dao, 
        uint256 _recvAmount, 
        uint256 _daoAmount, 
        uint256 _funds
        );
    event SetAlphaMigration(address _alphaMigration);
    event SetPublicMigration(address _publicMigration);
    event SetToken(address _GIZA);
    event SetTreasury(address _treasury);
    event SetDAO(address _dao);
    event ReclaimDAOFunds(address _dao, uint256 _amount);
    event ReclaimTokens(address _recv, uint256 _amount);
    
    modifier onlyInitialized() {
        require(isInitialized, "not initialized");
        _;
    }
    
    modifier notInitialized() {
        require( !isInitialized, "already initialized" );
        _;
    }

    function initialize (
        address _aToken,
        address _pToken,
        address _principle,
        address _alphaMarket,
        address _publicMarket,
        address _dao
    ) external onlyOwner() notInitialized() {
        aToken = IERC20(_aToken);
        pToken = IERC20(_pToken);
        principle = IERC20(_principle);
        alphaMarket = IAlphaMarket(_alphaMarket);
        publicMarket = IPublicMarket(_publicMarket);
        dao = _dao;
        isInitialized = true;

        emit Initialize(_aToken, _pToken, _principle, _alphaMarket, _publicMarket, _dao);
    }

    function mintTokenForAlphaMigration() external onlyOwner() onlyInitialized() {
        require(alphaMigration != address(0), "alpha migration has not be seted");
        require(alphaFunds().sub(spendedAlphaFunds) > 0, "alpha funds is zero");

        uint256 _value = alphaMintTokens();
        uint256 _funds = alphaFunds();
        _mintToken(alphaMigration, _funds, _value);
        spendedAlphaFunds = _funds;
    } 

    // note: if the public funds < publicMintTokens (10000 + 1000), 
    // dao should transfer principle to fulfill it gap through public market
    function mintTokenForPublicMigration() external onlyOwner() onlyInitialized() {
        require(publicMigration != address(0), "public migration has not be seted");
        require(publicFunds().sub(spendedPublicFunds) > 0, "public funds is zero");

        uint256 _value = publicMintTokens();
        uint256 _funds = publicFunds();
        _mintToken(publicMigration, _funds, _value);
        spendedPublicFunds = _funds;
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
        uint256 _profit = _totalValue.sub(_newValue, "mint profit for treasury is zero");

        principle.safeApprove(address(treasury), _funds);
        treasury.deposit(_funds, address(principle), _profit);
        GIZA.safeTransfer(_recv, _value);
        GIZA.safeTransfer(dao, _daoReward);

        emit MintTokens(_recv, dao, _value, _daoReward, _funds);
    }

    function setAlphaMigration(address _alphaMigration) external onlyOwner() onlyInitialized() {
        require(alphaMigration == address(0), "alpha migration has seted");
        require(_alphaMigration != address(0), "input alpha migration is zero");

        alphaMigration = _alphaMigration;

        emit SetAlphaMigration(_alphaMigration);
    }
    
    function setPublicMigration(address _publicMigration) external onlyOwner() onlyInitialized() {
        require(publicMigration == address(0), "public migration has seted");
        require(_publicMigration != address(0), "input public migration is zero");

        publicMigration = _publicMigration;

        emit SetPublicMigration(_publicMigration);
    }

    function setToken(address _GIZA) external onlyOwner() onlyInitialized() {
        require(address(GIZA) == address(0), "GIZA token has seted");
        require(_GIZA != address(0), "input GIZA token is zero");

        GIZA = IERC20(_GIZA);

        emit SetToken(_GIZA);
    }

    function setTreasury(address _treasury) external onlyOwner() onlyInitialized() {
        require(address(treasury) == address(0), "treasury token has seted");
        require(_treasury != address(0), "input treasury is zero");

        treasury = ITreasury(_treasury);

        emit SetTreasury(_treasury);
    }

    function setDAO(address _dao) external onlyOwner() {
        require(_dao != address(0), "dao address is zero");

        dao = _dao;

        emit SetDAO(_dao);
    }
    
    // dao will only reclaim the reward funds
    function reclaimDAOFunds(uint256 _amount) external onlyOwner() onlyInitialized() {
        require(daoFunds().sub(reclaimedDAOFunds) >= _amount, "amount above the dao funds");
        require(principle.balanceOf(address(this)) > _amount, "amount above treasury balance");
        require(dao != address(0), "dao address is zero");

        principle.safeTransfer(dao, _amount);
        reclaimedDAOFunds = reclaimedDAOFunds.add(_amount);

        emit ReclaimDAOFunds(dao, _amount);
    }

    function alphaMintTokens() public view returns (uint256) {
        if (!isInitialized) {
            return 0;
        }
        uint256 _alphaMintTokens = alphaMarket.mintTokens();
        return _alphaMintTokens;
    }

    function publicMintTokens() public view returns (uint256) {
        if (!isInitialized) {
            return 0;
        }
        uint256 _mintTokens = 20000;
        uint256 _publicMintTokens = _mintTokens.mul(10 ** GIZA.decimals());

        return _publicMintTokens;
    }

    function alphaFunds() public view returns (uint256) {
        if (!isInitialized) {
            return 0;
        }
        uint256 _alphaTotalFunds = alphaMarket.totalFunds();
        uint256 _fundsForDAOFromAlpha = _alphaTotalFunds.mul(daoFundPercent).div(100);
        uint256 _alphaFunds = _alphaTotalFunds.sub(_fundsForDAOFromAlpha);

        return  _alphaFunds;
    }

    function publicFunds() public view returns (uint256) {
        if (!isInitialized) {
            return 0;
        }
        uint256 _publicTotalFunds = publicMarket.totalFunds();
        uint256 _fundsForDAOFromPublic = _publicTotalFunds.mul(daoFundPercent).div(100);
        uint256 _publicFunds = _publicTotalFunds.sub(_fundsForDAOFromPublic);

        return  _publicFunds;
    }

    function daoFunds() public view returns (uint256) {
        if (!isInitialized) {
            return 0;
        }
        uint256 _alphaTotalFunds = alphaMarket.totalFunds();
        uint256 _fundsForDAOFromAlpha = _alphaTotalFunds.mul(daoFundPercent).div(100);

        uint256 _publicTotalFunds = publicMarket.totalFunds();
        uint256 _fundsForDAOFromPublic = _publicTotalFunds.mul(daoFundPercent).div(100);

        uint256 _daoFunds = _fundsForDAOFromAlpha.add(_fundsForDAOFromPublic);
        return  _daoFunds;
    }

    // The _recv and _amount can be voted by community
    function reclaimTokens(address _recv, uint256 _amount) external onlyOwner() onlyInitialized() {
        require(_recv != address(0), "recv address is zero");

        uint256 _balance = GIZA.balanceOf(address(this));
        require(_balance > _amount, "reclaim amount over balance");

        GIZA.safeTransfer(_recv, _amount);

        emit ReclaimTokens(_recv, _amount);
    }
}