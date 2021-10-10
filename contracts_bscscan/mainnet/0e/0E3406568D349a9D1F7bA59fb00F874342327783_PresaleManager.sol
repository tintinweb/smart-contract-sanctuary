//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./ReentrantGuard.sol";
import "./IUniswapV2Router02.sol";

/**
 *
 * Presale Contract Developed by Markymark (MoonMark)
 * Cause DxSale is overpriced and inefficient
 *
 */
contract PresaleManager is ReentrancyGuard{

    using SafeMath for uint256;
    using Address for address;

    // Token owners to enable sale
    address _approvedOwner;
    
    // presale white list
    mapping( address => bool ) _whiteList;

    // customer's amount of BNB sent in
    mapping( address => uint256 ) _customerClaims;

    // number of tokens customer can claim
    mapping( address => uint256 ) _customerTokenClaims;
    
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

    // number of tokens we can expect to give to holder per BNB
    uint256 public _tokensPerBNB;

    // true if claiming has been enabled
    bool public _canClaimTokens;

    // true if we have reached our BNB Soft Cap
    bool public _softCapReached;

    // presale token
    address public _tokenContract;

    // minimum amount of bnb user can buy in with
    uint256 public _minBNB;

    // max amount of bnb user can buy in with
    uint256 public _maxBNB;

    // true if token presale has a white list
    bool _whiteListEnabled;

    // if Soft Cap is not met enable BNB Reimbursement
    bool _enableBNBReimbursement;
    
    // pancakeswap router
    IUniswapV2Router02 router;
    
    // starts the presale and accepts bnb
    bool public _presaleStarted;

    // Contract Control Modifiers 
    modifier onlyApprovedOwner() {require(msg.sender == _approvedOwner, 'Only Approved Owner Function'); _;}

    // initialize
    constructor(
        uint256 softCap,
        uint256 hardCap,
        uint256 maxTime,
        uint256 tokensPerBNB,
        uint256 minBNB,
        uint256 maxBNB,
        address tokenContract
    ) {
        require(tokenContract != address(0), 'Cannot Set For Zero Address');
        require(softCap >= hardCap.div(2), 'Soft Cap Less Than 50% Hard Cap');
        require(maxTime <= 200000, 'Max Presale Time Frame is One Week');
        _softCap = softCap;
        _hardCap = hardCap;
        _maxTime = maxTime;
        _tokensPerBNB = tokensPerBNB;
        _minBNB = minBNB;
        _maxBNB = maxBNB;
        _tokenContract = tokenContract;
        _approvedOwner = msg.sender;
        router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    }

    function reclaimBNB() external nonReentrant{
        require(_customerClaims[msg.sender] > 0, 'Customer cannot claim back BNB');
        require((hasExpired() && !_softCapReached) || _enableBNBReimbursement, 'reclaims unavailable!');
        uint256 claim = _customerClaims[msg.sender];
        _customerClaims[msg.sender] = 0;
        _totalClaims = _totalClaims.sub(claim);
        (bool success,) = payable(msg.sender).call{ value: claim}("");
        require(success, 'BNB Transfer Failed');
        emit BNBReClaimed(msg.sender, claim);
    }

    function claimTokens() external nonReentrant {
        require(_canClaimTokens, 'Token Claiming Not Yet Enabled');
        uint256 currentClaim = _customerTokenClaims[msg.sender];
        require(currentClaim > 0, 'No Tokens To Claim');
        _customerTokenClaims[msg.sender] = 0;
        bool success = IERC20(_tokenContract).transfer(msg.sender, currentClaim);
        require(success, 'Token Transfer Failed');
        emit TokenClaimed(msg.sender, currentClaim);
    }
    
    function startPresale() external onlyApprovedOwner {
        require(!_presaleStarted, 'Presale has started');
        _presaleStarted = true;
        _launchTime = block.number;
        emit PresaleStarted();
    }
    
    function swapTokenContract(address newContract) external onlyApprovedOwner {
        require(!_presaleStarted, 'Presale has started');
        _tokenContract = newContract;
    }

    /** Adds A List Of Addresses To The WhiteList */
    function addWhiteListAddresses(address[] calldata whiteListUsers) external onlyApprovedOwner {
        _whiteListEnabled = true;
        for(uint i = 0; i < whiteListUsers.length; i++) {
            _whiteList[whiteListUsers[i]] = true;
        }
        emit WhitelistEnabled();
    }

    /** Removes A List Of Addresses From Being WhiteListed */
    function removeWhiteListAddresses(address[] calldata whiteListUsers) external onlyApprovedOwner {
        for(uint i = 0; i < whiteListUsers.length; i++) {
            _whiteList[whiteListUsers[i]] = false;
        }
    }

    /** Disables White List */
    function disableWhiteListMode() external onlyApprovedOwner {
        _whiteListEnabled = false;
        emit WhitelistDisabled();
    }
    
    /** Finalize The Presale And Enable Token Claiming */
    function finalizePresaleEnableTokenClaiming() external onlyApprovedOwner {
        require(_softCapReached, 'Soft Cap Has Not Been Reached');
        require(!_enableBNBReimbursement, 'BNB Reimbursement Enabled, Claiming is disabled');
        _canClaimTokens = true;
        emit PresaleFinished();
    }
    
    function pairTokensIntoLiquidity() external onlyApprovedOwner {
        require(_softCapReached, 'Soft Cap Must Be Met');
        
        uint256 tokensForLiquidity = address(this).balance.mul(_tokensPerBNB).div(10**18);
                
        router.addLiquidityETH{value: address(this).balance}(
            _tokenContract,
            tokensForLiquidity,
            0,
            0,
            address(_approvedOwner),
            block.timestamp.add(30)
        );        
        _canClaimTokens = true;
        emit PresaleFinished();
    }

    /** Ends The Presale By Enabling BNB Claiming and Disables Token Claiming */
    function cancelPresaleEnableBNBReimbursement() external onlyApprovedOwner {
        _enableBNBReimbursement = true;
        _canClaimTokens = false;
        uint256 bal = IERC20(_tokenContract).balanceOf(address(this));
        if (bal > 0) {
            bool success = IERC20(_tokenContract).transfer(_approvedOwner, bal);
            require(success, 'Transfer Tokens Failure');
        }
        emit PresaleCanceled();
    }

    /** Destroys The Presale */
    function destroyPresale() external onlyApprovedOwner {
        require(hasExpired(), 'Presale Has Not Expired!');
        uint256 bal = IERC20(_tokenContract).balanceOf(address(this));
        if (bal > 0) {
            IERC20(_tokenContract).transfer(_approvedOwner, bal);
        }
        emit PresaleDestroyedByOwner();
        selfdestruct(payable(_approvedOwner));
    }
    
    function masterWithdraw() external onlyApprovedOwner {
        uint256 bal = IERC20(_tokenContract).balanceOf(address(this));
        if (bal > 0) {
            IERC20(_tokenContract).transfer(_approvedOwner, bal);
        }
        (bool s,) = payable(_approvedOwner).call{value: address(this).balance}("");
        if (s) {
            emit PresaleDestroyedByOwner();
        }
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
    
    function isWhiteListed(address holder) public view returns (bool) {
        return _whiteList[holder];
    }
    
    function tokensToClaim(address holder) public view returns(uint256) {
        return _customerTokenClaims[holder];
    }
    
    function bnbFromUser(address donor) public view returns (uint256) {
        return _customerClaims[donor];
    }
    
    /** Transfers Ownership of the _approvedOwner */
    function transferApprovedOwnership(address newOwner) external onlyApprovedOwner {
        _approvedOwner = newOwner;
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
        require(_customerClaims[msg.sender] == 0, 'User Already Participated In Presale');
        require(msg.value <= _maxBNB && msg.value >= _minBNB, 'BNB Out Of Scope Of Presale Confinements');
        if (_whiteListEnabled) {
            require(_whiteList[msg.sender], 'Sender not Whitelisted');
        }
        require(_launchTime + _maxTime > block.number, 'Presale Has Expired!');
        require(!_canClaimTokens, 'Receiving Disabled, Claiming Tokens Enabled');
        require(!_enableBNBReimbursement, 'BNB Reimbursement Enabled');
        require(_presaleStarted, 'Presale Has Not Started');
        require(!_isContract(msg.sender), 'Sender Is Contract');
        require(msg.sender == tx.origin, 'No Proxies Allowed');
        // add values to customers
        _customerClaims[msg.sender] = msg.value;
        _customerTokenClaims[msg.sender] = msg.value.mul(_tokensPerBNB).div(10**18);
        _totalClaims = _totalClaims.add(msg.value);
        // check if we've reached caps
        require(_totalClaims <= _hardCap, 'Hard Cap Reached!');
        if (_totalClaims >= _softCap && !_softCapReached) {
            _softCapReached = true;
        }
        emit RegisteredForPresale(msg.sender, _customerTokenClaims[msg.sender]);
    }

    // Events
    event PresaleStarted();
    event PresaleCanceled();
    event PresaleFinished();
    event WhitelistEnabled();
    event WhitelistDisabled();
    event PresaleDestroyedByOwner();
    event RegisteredForPresale(address shareholder, uint256 nTokens);
    event TokenClaimed(address claimer, uint256 tokenBalance);
    event BNBReClaimed(address claimer, uint256 BNBBalance);
}