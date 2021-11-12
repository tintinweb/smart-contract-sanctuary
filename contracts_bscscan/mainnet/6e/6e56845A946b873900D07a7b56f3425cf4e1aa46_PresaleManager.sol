//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./ReentrantGuard.sol";
import "./IUniswapV2Router02.sol";

/**
 *
 * Presale Contract Developed by Markymark ( MoonMark / DeFi Mark )
 * Cause DxSale is overpriced and inefficient
 *
 */
contract PresaleManager is ReentrancyGuard{

    using SafeMath for uint256;
    using Address for address;
    
    // Token owners to enable sale
    address _owner;

    // amount of presale customers
    address[] _presaleCustomers;

    struct User {
        uint256 bnbToClaim;
        uint256 tokensToClaim;
    }

    // list of Presale Users
    mapping ( address => User ) users;

    // total amount of BNB Sent
    uint256 private _totalClaims;
    
    // minimum amount of bnb to approve presale
    uint256 public immutable _softCap;

    // maximum amount of BNB to receive for presale
    uint256 public immutable _hardCap;

    // maximum amount of time allotted for Presale
    uint256 public _maxTime;

    // when the contract was created
    uint256 private _launchTime;

    // number of tokens to give to holder per BNB
    uint256 _tokensPerBNB;
    
    // number of tokens to pair into Liquidity per bnb
    uint256 _tokensPerBNBLiquidity;

    // true if claiming has been enabled
    bool public _canClaimTokens;

    // true if we have reached our BNB Soft Cap
    bool public _softCapReached;
    
    // total tokens for users to claim
    uint256 public _totalTokenClaims;

    // presale token
    address immutable _tokenContract;

    // minimum amount of bnb user can buy in with
    uint256 _minBNB;

    // max amount of bnb user can buy in with
    uint256 _maxBNB;

    // true if token presale has a white list
    bool public whiteListEnabled;

    // if Soft Cap is not met enable BNB Reimbursement
    bool _enableBNBReimbursement;
    
    // auto distribution index
    uint256 distributeIndex;
    
    // pancakeswap router
    IUniswapV2Router02 router;
    
    // starts the presale and accepts bnb
    bool _presaleStarted;

    // fee collector
    address feeTo;

    // Contract Control Modifiers 
    modifier onlyOwner() {require(msg.sender == _owner, 'Only Owner Function'); _;}

    // initialize
    constructor(
        uint256 softCap,
        uint256 hardCap,
        uint256 maxTime,
        uint256 tokensPerBNB,
        uint256 tokensPerBNBLiquidity,
        uint256 minBNB,
        uint256 maxBNB,
        address tokenContract,
        address FeeTo
    ) {
        require(tokenContract != address(0), 'Cannot Set For Zero Address');
        require(maxTime <= 200000, 'Max Presale Time Frame is One Week');
        _softCap = softCap;
        _hardCap = hardCap;
        _maxTime = maxTime;
        _tokensPerBNB = tokensPerBNB;
        _tokensPerBNBLiquidity = tokensPerBNBLiquidity;
        _minBNB = minBNB;
        _maxBNB = maxBNB;
        _tokenContract = tokenContract;
        _owner = msg.sender;
        router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        feeTo = FeeTo;
    }

    function reclaimBNB() external nonReentrant{
        require(users[msg.sender].bnbToClaim > 0, 'Customer cannot claim back BNB');
        require((hasExpired() && !_softCapReached) || _enableBNBReimbursement, 'reclaims unavailable!');
        uint256 claim = users[msg.sender].bnbToClaim;
        users[msg.sender].bnbToClaim = 0;
        _totalClaims = _totalClaims.sub(claim);
        (bool success,) = payable(msg.sender).call{ value: claim, gas:26000}("");
        require(success, 'BNB Transfer Failed');
        emit BNBReClaimed(msg.sender, claim);
    }

    function claimTokens() external nonReentrant {
        require(_canClaimTokens, 'Token Claiming Not Yet Enabled');
        uint256 currentClaim = users[msg.sender].tokensToClaim;
        require(currentClaim > 0, 'No Tokens To Claim');
        users[msg.sender].tokensToClaim = 0;
        bool success = IERC20(_tokenContract).transfer(msg.sender, currentClaim);
        require(success, 'Token Transfer Failed');
        emit TokenClaimed(msg.sender, currentClaim);
    }
    
    function autoDistributeTokensToHolders(uint256 iterations) external nonReentrant {
        require(_canClaimTokens, 'Token Claiming Not Yet Enabled');
        bool success;
        for (uint i = 0; i < iterations; i++) {
            if (distributeIndex >= _presaleCustomers.length) {
                distributeIndex = 0;
            }
            uint256 claim = users[_presaleCustomers[distributeIndex]].tokensToClaim;
            if (claim > 0) {
                success = IERC20(_tokenContract).transfer(_presaleCustomers[distributeIndex], claim);
                if (success) {
                    users[_presaleCustomers[distributeIndex]].tokensToClaim = 0;
                }
            }
            distributeIndex++;
        }
    }
    
    /** Starts Presale Enabling BNB Receiving */
    function startPresale() external onlyOwner {
        _presaleStarted = true;
        _launchTime = block.number;
        emit PresaleStarted();
    }
    
    /** Finalize The Presale And Enable Token Claiming */
    function forcefullyFinalizePresaleEnableTokenClaiming() external onlyOwner {
        require(!_enableBNBReimbursement, 'BNB Reimbursement Enabled, Claiming is disabled');
        
        _canClaimTokens = true;
        _softCapReached = true;
        
        // balance left after liquidity pairing
        uint256 balLeft = IERC20(_tokenContract).balanceOf(address(this));
        
        if (balLeft > _totalTokenClaims) {
            uint256 diff = balLeft.sub(_totalTokenClaims);
            IERC20(_tokenContract).transfer(_owner, diff);
        }
        
        // pay fee
        (bool s,) = payable(feeTo).call{value: address(this).balance.div(50)}("");
        require(s, 'Fee Payment Failed');
        
        // return presale amount to owner
        (bool ss,) = payable(_owner).call{value: address(this).balance}("");
        require(ss, 'Fee Payment Failed');
        
        emit PresaleFinished();
    }
    
    function emergencyWithdraw() external onlyOwner {
        
        uint256 bal = IERC20(_tokenContract).balanceOf(address(this));
        if (bal > 0) {
            IERC20(_tokenContract).transfer(_owner, bal);
        }
        if (address(this).balance > 0) {
            (bool s,) = payable(_owner).call{value: address(this).balance}("");
            require(s, 'Fee Payment Failed');
        }
    }
    
    /** Pairs Tokens Into Liquidity, Enabling Users To Claim Tokens*/
    function pairTokensIntoLiquidityEnableTokenClaiming() external onlyOwner {
        require(_softCapReached, 'Soft Cap Must Be Met');
        require(!_enableBNBReimbursement, 'BNB Reimbursement Enabled, Claiming is disabled');

        // pay fee
        (bool s,) = payable(feeTo).call{value: address(this).balance.div(50)}("");
        require(s, 'Fee Payment Failed');

        // bnb to pair into liquidity
        uint256 bnbForLiquidity = address(this).balance;

        // tokens to pair into liquidity
        uint256 tokensForLiquidity = bnbForLiquidity.mul(_tokensPerBNBLiquidity).div(10**18);

        // approve router
        IERC20(_tokenContract).approve(address(router), tokensForLiquidity*2);

        // add liquidity
        router.addLiquidityETH{value: bnbForLiquidity}(
            _tokenContract,
            tokensForLiquidity,
            0,
            0,
            address(_owner),
            block.timestamp.add(30)
        );
        
        // enable token claiming
        _canClaimTokens = true;
        
        // balance left after liquidity pairing
        uint256 balLeft = IERC20(_tokenContract).balanceOf(address(this));
        
        if (balLeft > _totalTokenClaims) {
            uint256 diff = balLeft.sub(_totalTokenClaims);
            
            IERC20(_tokenContract).transfer(_owner, diff);
        }

        // tell blockchain
        emit TokensPairedIntoLiquidity(tokensForLiquidity, bnbForLiquidity);
    }

    /** Ends The Presale By Enabling BNB Claiming and Disables Token Claiming */
    function cancelPresaleEnableBNBReimbursement() external onlyOwner {
        _enableBNBReimbursement = true;
        _canClaimTokens = false;
        uint256 bal = IERC20(_tokenContract).balanceOf(address(this));
        if (bal > 0) {
            bool success = IERC20(_tokenContract).transfer(_owner, bal);
            require(success, 'Transfer Tokens Failure');
        }
        emit PresaleCanceled();
    }

    /** Destroys The Presale */
    function destroyPresale() external onlyOwner {
        require(hasExpired(), 'Presale Has Not Expired!');
        uint256 bal = IERC20(_tokenContract).balanceOf(address(this));
        if (bal > 0) {
            IERC20(_tokenContract).transfer(_owner, bal);
        }
        if (address(this).balance > 0) {
            (bool s,) = payable(_owner).call{value: address(this).balance}("");
            require(s, 'Failure on BNB Withdrawal');
        }
        emit PresaleDestroyedByOwner();
    }

    function bnbLeftUntilHardCapReached() public view returns (uint256) {
        if (_hardCap <= _totalClaims) return 0;
        return _hardCap.sub(_totalClaims);
    }

    function hardCapReached() public view returns (bool) {
        return bnbLeftUntilHardCapReached() <= 10**15; // less than 0.001 BNB
    }

    function totalBNBReceived() public view returns (uint256) {
        return _totalClaims;
    }
    
    function tokenBalanceInContract() public view returns (uint256) {
        return IERC20(_tokenContract).balanceOf(address(this));
    }

    function blocksLeftUntilExpiration() public view returns (uint256) {
        uint256 endTime = _launchTime.add(_maxTime);
        return endTime > block.number ? endTime.sub(block.number) : 0;
    }

    function hasExpired() public view returns (bool) {
        return blocksLeftUntilExpiration() == 0;
    }

    function tokensToClaim(address holder) external view returns(uint256) {
        return users[holder].tokensToClaim;
    }
    
    function bnbReceivedFromUser(address holder) external view returns (uint256) {
        return users[holder].bnbToClaim;
    }
    
    function getRegisteredUsers() external view returns (address[] memory) {
        return _presaleCustomers;
    }
    
    /** Transfers Ownership of the _owner */
    function transferApprovedOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }

    /**
     * @notice Check if an address is a contract
     */
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    /** Register Sender In Presale */
    receive() external payable {
        
        // make checks
        require(users[msg.sender].bnbToClaim == 0, 'User Already Participated In Presale');
        require(msg.value <= _maxBNB && msg.value >= _minBNB, 'BNB Out Of Scope Of Presale Confinements');
        require(_launchTime + _maxTime > block.number, 'Presale Has Expired!');
        require(!_canClaimTokens, 'Receiving Disabled, Claiming Tokens Enabled');
        require(!_enableBNBReimbursement, 'BNB Reimbursement Enabled');
        require(_presaleStarted, 'Presale Has Not Started');
        require(!_isContract(msg.sender), 'Sender Is Contract');
        require(msg.sender == tx.origin, 'No Proxies Allowed');
        
        // add values to customers
        users[msg.sender].bnbToClaim = msg.value;
        users[msg.sender].tokensToClaim = msg.value.mul(_tokensPerBNB).div(10**18);
        _totalTokenClaims = _totalTokenClaims.add(users[msg.sender].tokensToClaim);
        _presaleCustomers.push(msg.sender);
        _totalClaims = _totalClaims.add(msg.value);
        
        // check if we've reached caps
        require(_totalClaims <= _hardCap, 'Hard Cap Reached!');
        if (_totalClaims >= _softCap && !_softCapReached) {
            _softCapReached = true;
        }
        
        // tell blockchain
        emit UserRegisteredInPresale(msg.sender, users[msg.sender].tokensToClaim);
    }

    // Events
    event PresaleStarted();
    event PresaleCanceled();
    event PresaleFinished();
    event WhitelistEnabled();
    event WhitelistDisabled();
    event PresaleDestroyedByOwner();
    event TokensPairedIntoLiquidity(uint256 tokensPaired, uint256 bnbPaired);
    event UserRegisteredInPresale(address user, uint256 tokenClaim);
    event TokenClaimed(address claimer, uint256 tokenBalance);
    event BNBReClaimed(address claimer, uint256 BNBBalance);
}