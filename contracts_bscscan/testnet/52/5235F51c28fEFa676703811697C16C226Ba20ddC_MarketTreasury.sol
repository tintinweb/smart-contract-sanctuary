/**
 *Submitted for verification at BscScan.com on 2021-11-16
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
    function marketPrice() external view returns (uint256);
}

interface IMarketCalculator {
    function principleAmount(
        uint256 _amount, 
        uint256 _marketPrice, 
        uint256 _decimals
    ) external pure returns(uint256);
    function marketPrice(
        uint256 _totalFunds, 
        uint256 _mintTokens, 
        uint256 _prinDecimals, 
        uint256 _tokenDecimals, 
        uint256 _decimals
    ) external pure returns (uint256);
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

    address public liquitityManager;

    address public team;
    uint256 public teamRewardPercent = 10; // 10%
    uint256 public teamFundPercent = 20; // 20%
    uint256 public liquidFundPercent = 60; // 60%
    uint256 private reclaimedTeamFunds = 0;
    uint256 private spendedAlphaFunds = 0;
    uint256 private spendedPublicFunds = 0;
    uint256 private spendedLiquidFunds = 0;
    uint256 private mintedAlphaTokens = 0;
    uint256 private mintedPublicTokens = 0;

    bool public isInitialized;

    event Initialize(
        address _aToken,
        address _pToken,
        address _principle,
        address _alphaMarket,
        address _publicMarket,
        address _team
    );
    event MintTokens(
        address _recv, 
        address team, 
        uint256 _recvAmount, 
        uint256 _teamAmount, 
        uint256 _funds
        );
    event ManageLiquidity(address _liquitityManager, uint256 _liquidFunds);
    event SetAlphaMigration(address _alphaMigration);
    event SetPublicMigration(address _publicMigration);
    event SetToken(address _GIZA);
    event SetTreasury(address _treasury);
    event SetTeam(address _team);
    event SetLiquitityManager(address _liquitityManager);
    event ReclaimTeamFunds(address _team, uint256 _amount);
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
        address _team
    ) external onlyOwner() notInitialized() {
        aToken = IERC20(_aToken);
        pToken = IERC20(_pToken);
        principle = IERC20(_principle);
        alphaMarket = IAlphaMarket(_alphaMarket);
        publicMarket = IPublicMarket(_publicMarket);
        team = _team;
        isInitialized = true;

        emit Initialize(_aToken, _pToken, _principle, _alphaMarket, _publicMarket, _team);
    }

    function mintTokenForAlphaMigration() external onlyOwner() onlyInitialized() {
        require(alphaMigration != address(0), "alpha migration has not be seted");
        // 40% funds will be used to mint tokens.
        uint256 _funds = alphaMintFunds();
        uint256 _value = alphaMintTokens().sub(mintedAlphaTokens);
        _mintToken(alphaMigration, _funds, _value);

        spendedAlphaFunds = spendedAlphaFunds.add(_funds);
        mintedAlphaTokens = mintedAlphaTokens.add(_value);
    } 

    // @note: if the public funds < publicMintTokens (10000 + 1000), 
    // team should transfer principle to fulfill it gap through public market
    function mintTokenForPublicMigration() external onlyOwner() onlyInitialized() {
        require(publicMigration != address(0), "public migration has not be seted");
        uint256 _funds = publicMintFunds();
        uint256 _value = publicMintTokens().sub(mintedPublicTokens);
        _mintToken(publicMigration, _funds, _value);

        spendedPublicFunds = spendedPublicFunds.add(_funds);
        mintedPublicTokens = mintedPublicTokens.add(_value);
    }

    // @note: remember to add MarketTreasury as Treasury ReserveDepositor (queue and toggle 0)
    // auto mint teamRewardPercent tokens to team, and the tokens will be staked and locked
    function _mintToken(address _recv, uint256 _funds, uint256 _value) private {
        require(address(GIZA) != address(0), "GIZA token has not be seted");
        require(address(treasury) != address(0), "treasury has not be seted");
        require(team != address(0), "team address is zero");

        uint256 _teamReward = _value.mul(teamRewardPercent).div(100);
        uint256 _newValue = _value.add(_teamReward);
        uint256 _totalValue = _funds.mul(10**GIZA.decimals()).div(10**principle.decimals());
        uint256 _profit = _totalValue.sub(_newValue, "mint profit for treasury is zero");

        principle.safeApprove(address(treasury), _funds);
        treasury.deposit(_funds, address(principle), _profit);
        GIZA.safeTransfer(_recv, _value);
        GIZA.safeTransfer(team, _teamReward);

        emit MintTokens(_recv, team, _value, _teamReward, _funds);
    }

    // @note: add liquidity manually by liquidity manager
    function manageLiquidity() external onlyOwner() onlyInitialized() {
        // 60% funds will be add into LP Pool.
        uint256 _liquidFunds = liquidFunds();
        principle.safeTransfer(liquitityManager, _liquidFunds);
        spendedLiquidFunds = spendedLiquidFunds.add(_liquidFunds);

        emit ManageLiquidity(liquitityManager, _liquidFunds);
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

    function setLiquitityManager(address _liquitityManager) external onlyOwner() onlyInitialized() {
        require(liquitityManager == address(0), "liquidity manager has seted");
        require(_liquitityManager != address(0), "liquidity manager is zero");

        liquitityManager = _liquitityManager;

        emit SetLiquitityManager(_liquitityManager);
    }

    function setTeam(address _team) external onlyOwner() onlyInitialized() {
        require(_team != address(0), "team address is zero");

        team = _team;

        emit SetTeam(_team);
    }
    
    // team will only reclaim the reward funds
    function reclaimTeamFunds(uint256 _amount) external onlyOwner() onlyInitialized() {
        require(teamFunds().sub(reclaimedTeamFunds) >= _amount, "amount above the team funds");
        require(principle.balanceOf(address(this)) >= _amount, "amount above treasury balance");
        require(team != address(0), "team address is zero");

        principle.safeTransfer(team, _amount);
        reclaimedTeamFunds = reclaimedTeamFunds.add(_amount);

        emit ReclaimTeamFunds(team, _amount);
    }

    // The _recv and _amount can be voted by community
    function reclaimTokens(address _recv, uint256 _amount) external onlyOwner() onlyInitialized() {
        require(_recv != address(0), "recv address is zero");

        uint256 _balance = GIZA.balanceOf(address(this));
        require(_balance >= _amount, "reclaim amount over balance");

        GIZA.safeTransfer(_recv, _amount);

        emit ReclaimTokens(_recv, _amount);
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
        uint256 _mintTokens = 40000;
        uint256 _publicMintTokens = _mintTokens.mul(10 ** GIZA.decimals());
        return _publicMintTokens;
    }

    function alphaFunds() public view returns (uint256) {
        if (!isInitialized) {
            return 0;
        }
        uint256 _alphaTotalFunds = alphaMarket.totalFunds();
        uint256 _fundsForTeamFromAlpha = _alphaTotalFunds.mul(teamFundPercent).div(100);
        uint256 _alphaFunds = _alphaTotalFunds.sub(_fundsForTeamFromAlpha);
        return  _alphaFunds;
    }

    function alphaLiquidFunds() private view returns (uint256) {
        if (!isInitialized) {
            return 0;
        }

        uint256 _alphaFunds = alphaFunds();
        uint256 _alphaLiquidFunds = _alphaFunds.mul(liquidFundPercent).div(100);

        return _alphaLiquidFunds;
    }

    function alphaMintFunds() public view returns (uint256) {
        if (!isInitialized) {
            return 0;
        }

        uint256 _alphaFunds = alphaFunds();
        uint256 _alphaMintFunds = _alphaFunds.sub(alphaLiquidFunds());

        return _alphaMintFunds.sub(spendedAlphaFunds);
    }

    function publicFunds() public view returns (uint256) {
        if (!isInitialized) {
            return 0;
        }
        uint256 _publicTotalFunds = publicMarket.totalFunds();
        uint256 _fundsForTeamFromPublic = _publicTotalFunds.mul(teamFundPercent).div(100);
        uint256 _publicFunds = _publicTotalFunds.sub(_fundsForTeamFromPublic);
        return  _publicFunds;
    }

    function publicLiquidFunds() private view returns (uint256) {
        if (!isInitialized) {
            return 0;
        }

        uint256 _publicFunds = publicFunds();
        uint256 _publicLiquidFunds = _publicFunds.mul(liquidFundPercent).div(100);

        return _publicLiquidFunds;
    }

    function publicMintFunds() public view returns (uint256) {
        if (!isInitialized) {
            return 0;
        }

        uint256 _publicFunds = publicFunds();
        uint256 _publicMintFunds = _publicFunds.sub(publicLiquidFunds());

        return _publicMintFunds.sub(spendedPublicFunds);
    }

    function liquidFunds() public view returns (uint256) {
        return alphaLiquidFunds().add(publicLiquidFunds()).sub(spendedLiquidFunds);
    }

    function teamFunds() public view returns (uint256) {
        if (!isInitialized) {
            return 0;
        }
        uint256 _totalFunds = alphaMarket.totalFunds().add(publicMarket.totalFunds());
        uint256 _teamFunds = _totalFunds.sub(alphaFunds()).sub(publicFunds());
        return  _teamFunds;
    }
}