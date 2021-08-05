// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./SafeERC20.sol";

contract Launchpad{

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
   
    uint256 private constant _BASE_PRICE = 100000000000;

    uint256 private constant _totalPercent = 10000;
    
    uint256 private constant _fee1 = 100;

    uint256 private constant _fee3 = 300;

    address private constant _layerFeeAddress = 0xa6A7cFCFEFe8F1531Fc4176703A81F570d50D6B5;
    
    address private constant _stakeFeeAddress = 0xfB5B0474B28f18A635579c1bF073fc05bE1BB63b;
    
    address private constant _supportFeeAddress = 0xD3cDe6FA51A69EEdFB1B8f58A1D7DCee00EC57A8;

    mapping (address => uint256) private _balancesToClaim;

    mapping (address => uint256) private _balancesToClaimTokens;

    uint256 private _liquidityPercent;

    uint256 private _teamPercent;

    uint256 private _end;

    uint256 private _start;

    uint256 private _releaseTime;
    
    uint256[3] private _priceInv;
     
    uint256[3] private _caps;

    uint256 private _priceUniInv;

    bool    private _isRefunded = false;

    bool    private _isSoldOut = false;

    bool    private _isLiquiditySetup = false;

    uint256 private _raisedETH;

    uint256 private _claimedAmount;

    uint256 private _softCap;

    uint256 private _maxCap;

    address private _teamWallet;

    address private _owner;
    
    address private _liquidityCreator;

    IERC20 public _token;
    
    string private _tokenName;
    
    string private _tokenSymbol;

    string private _siteUrl;
    
    string private _paperUrl;

    string private _twitterUrl;

    string private _telegramUrl;

    string private _mediumUrl;
    
    string private _gitUrl;
    
    string private _discordUrl;
    
    string private _tokenDesc;
    
    uint256 private _tokenTotalSupply;
    
    uint256 private _tokensForSale;
    
    uint256 private _minContribution = 1 ether;
    
    uint256 private _maxContribution = 50 ether;
    
    uint256 private _round;
    
    bool private _uniListing;
    
    bool private _tokenMint;
    
    /**
    * @dev Emitted when maximum value of ETH is raised
    *
    */    
    event SoldOut();
    
    /**
    * @dev Emitted when ETH are Received by this wallet
    *
    */
    event Received(address indexed from, uint256 value);
    
    /**
    * @dev Emitted when tokens are claimed by user
    *
    */
    event Claimed(address indexed from, uint256 value);
    /**
    * @dev Emitted when refunded if not successful
    *
    */
    event Refunded(address indexed from, uint256 value);
    
    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }    

    constructor(
        IERC20 token, 
        uint256 priceUniInv, 
        uint256 softCap, 
        uint256 maxCap, 
        uint256 liquidityPercent, 
        uint256 teamPercent, 
        uint256 end, 
        uint256 start, 
        uint256 releaseTime,
        uint256[3] memory caps, 
        uint256[3] memory priceInv,
        address owner, 
        address teamWallet,
        address liquidityCreator
    ) 
    public 
    {
        require(start > block.timestamp, "start time needs to be above current time");
        require(releaseTime > block.timestamp, "release time above current time");
        require(end > start, "End time above start time");
        require(liquidityPercent <= 3000, "Max Liquidity allowed is 30 %");
        require(owner != address(0), "Not valid address" );
        require(caps.length > 0, "Caps can not be zero" );
        require(caps.length == priceInv.length, "Caps and price not same length" );
    
        uint256 totalPercent = teamPercent.add(liquidityPercent).add(_fee1.mul(2)).add(_fee3);
        require(totalPercent == _totalPercent, "Funds are distributed max 100 %");

        _softCap = softCap;
        _maxCap = maxCap;
        _start = start;
        _end = end;
        _liquidityPercent = liquidityPercent;
        _teamPercent = teamPercent;
        _caps = caps;
        _priceInv = priceInv;
        _owner = owner;
        _liquidityCreator = liquidityCreator;
        _releaseTime = releaseTime;
        _token = token;
        _teamWallet = teamWallet;
        _priceUniInv = priceUniInv;
    }
    
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = _newOwner;
    }    
    
    /**
    * @dev Function to set the end time
    * @param end - end time
    */    
    function setEndTime(uint256 end) external onlyOwner {
        require(end > _start, "End time above start time");
        _end = end;
    }
    
    /**
    * @dev Function to set the release time
    * @param releaseTime - release time
    */       
    function setReleaseTime(uint256 releaseTime) external onlyOwner {
        require(releaseTime > block.timestamp, "release time above current time");
        _releaseTime = releaseTime;
    }    
    
    /**
    * @dev Function to set projetct details
    * @param tokenName - token name
    * @param tokenSymbol - token symbol
    * @param siteUrl - site url
    * @param paperUrl - paper url
    * @param twitterUrl - twitter url
    * @param telegramUrl - telegram url
    * @param mediumUrl - medium url
    * @param gitUrl - git url
    * @param discordUrl - discord url
    * @param tokenDesc - token desc
    * @param tokensForSale - amount tokens for sale
    * @param tokenTotalSupply - total token supply
    * @param uniListing - is uniswap listing
    * @param tokenMint - is token mint
    */    
    function setDetails(
        string memory tokenName,
        string memory tokenSymbol,
        string memory siteUrl,
        string memory paperUrl,
        string memory twitterUrl,
        string memory telegramUrl,
        string memory mediumUrl,
        string memory gitUrl,
        string memory discordUrl,
        string memory tokenDesc,
        uint256 tokensForSale,
        uint256 tokenTotalSupply,
        bool uniListing,
        bool tokenMint
    ) external onlyOwner {
        _tokenName = tokenName;
        _tokenSymbol = tokenSymbol;
        _siteUrl = siteUrl;
        _paperUrl = paperUrl;
        _twitterUrl = twitterUrl;
        _telegramUrl = telegramUrl;
        _mediumUrl = mediumUrl;
        _gitUrl = gitUrl;
        _discordUrl = discordUrl;
        _tokenDesc = tokenDesc;
        _tokensForSale = tokensForSale;
        _uniListing = uniListing;
        _tokenMint = tokenMint;
        _tokenTotalSupply = tokenTotalSupply;
    }
    
    /**
    * @dev Function to get details of project part-1.
    */
    function getDetails() public view returns 
    (
        uint256 priceUniInv,
        address owner,
        address teamWallet, 
        uint256 softCap, 
        uint256 maxCap, 
        uint256 liquidityPercent, 
        uint256 teamPercent, 
        uint256 end, 
        uint256 start, 
        uint256 releaseTime,
        uint256 raisedETH,
        uint256 tokensForSale,
        uint256 minContribution,
        uint256 maxContribution
    ) {
        priceUniInv = _priceUniInv;
        owner = _owner;
        teamWallet = _teamWallet; 
        softCap = _softCap; 
        maxCap = _maxCap; 
        liquidityPercent = _liquidityPercent; 
        teamPercent = _teamPercent;
        end = _end;
        start = _start; 
        releaseTime = _releaseTime;
        raisedETH = _raisedETH;
        tokensForSale = _tokensForSale;
        minContribution = _minContribution;
        maxContribution = _maxContribution;
    }

    /**
    * @dev Function to get details of project part-2.
    */
    function getMoreDetails() public view returns 
    (
        bool uniListing,
        bool tokenMint,
        bool isRefunded,
        bool isSoldOut,
        string memory tokenName,
        string memory tokenSymbol,
        uint256 tokenTotalSupply,
        uint256 liquidityLock,
        uint256 round
    ) {
        uniListing = _uniListing;
        tokenMint = _tokenMint;
        isRefunded = _isRefunded;
        isSoldOut = _isSoldOut;
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        tokenTotalSupply = _tokenTotalSupply;
        liquidityLock = _maxCap.mul(_liquidityPercent).div(_totalPercent);
        round = _round;
    }

    /**
    * @dev Function to get details of project
    * @return details of project part-3.
    */
    function getInfos() public view returns (string memory, string memory) {
        string memory res = '';
        res = append(_siteUrl, '|', _paperUrl, '|', _twitterUrl);
        res = append(res, '|', _telegramUrl, '|', _mediumUrl );
        res = append(res, '|', _gitUrl, '|', _discordUrl );
        return(res, _tokenDesc);
    }

    /**
    * @dev Function to get details of project for listing
    */
    function getMinInfos() public view returns (
        string memory siteUrl,
        string memory tokenName,
        bool isRefunded,
        bool isSoldOut,
        uint256 start, 
        uint256 end,
        uint256 softCap,
        uint256 maxCap,
        uint256 raisedETH
    ) {
        siteUrl = _siteUrl;
        tokenName = _tokenName;
        isRefunded = _isRefunded;
        isSoldOut = _isSoldOut;
        start = _start;
        end = _end;
        softCap = _softCap;
        maxCap = _maxCap;
        raisedETH = _raisedETH;
    }
    
    /**
    * @dev Function to get the length of caps array
    * @return length
    */        
    function getCapSize() public view returns(uint) {
        return _caps.length;
    }

    /**
    * @dev Function to get the cap value, price inverse and amount.
    * @param index - cap index.
    * @return cap value, price inverse and amount.
    */ 
    function getCapPrice(uint index) public view returns(uint, uint, uint) {
        return (_caps[index], _priceInv[index], ( _caps[index].mul(_BASE_PRICE).div(_priceInv[index])));
    }

    /**
    * @dev Function to get the balance to claim of user in ETH.
    * @param account - user address.
    * @return balance to claim.
    */
    function getBalanceToClaim(address account) public view returns (uint256) {
        return _balancesToClaim[account];
    }

    /**
    * @dev Function to get the balance to claim of user in TOKEN.
    * @param account - user address.
    * @return balance to claim.
    */
    function getBalanceToClaimTokens(address account) public view returns (uint256) {
        return _balancesToClaimTokens[account];
    }
    
    /**
    * @dev Receive ETH and updates the launchpad values.
    */
    receive() external payable {
        require(block.timestamp > _start , "LaunchpadToken: not started yet");
        require(block.timestamp < _end , "LaunchpadToken: finished");
        require(_isRefunded == false , "LaunchpadToken: Refunded is activated");
        require(_isSoldOut == false , "LaunchpadToken: SoldOut");
        uint256 amount = msg.value;
        require(amount >= _minContribution && amount <= _maxContribution, 'Amount must be between MIN and MAX');
        uint256 price = _priceInv[2];
        require(amount > 0, "LaunchpadToken: eth value sent needs to be above zero");
      
        _raisedETH = _raisedETH.add(amount);
        uint total = 0;
        for (uint256 index = 0; index < _caps.length; index++) {
            total = total + _caps[index];
            if(_raisedETH < total){
                price = _priceInv[index];
                _round = index;
                break;
            }
        }
        
        _balancesToClaim[msg.sender] = _balancesToClaim[msg.sender].add(amount);
        _balancesToClaimTokens[msg.sender] = _balancesToClaimTokens[msg.sender].add(amount.mul(_BASE_PRICE).div(price));

        if(_raisedETH >= _maxCap){
            _isSoldOut = true;
            uint256 refundAmount = _raisedETH.sub(_maxCap);
            if(refundAmount > 0){
                // Subtract value that is higher than maxCap
                 _raisedETH = _raisedETH.sub(refundAmount);
                _balancesToClaim[msg.sender] = _balancesToClaim[msg.sender].sub(refundAmount);
                _balancesToClaimTokens[msg.sender] = _balancesToClaimTokens[msg.sender].sub(refundAmount.mul(_BASE_PRICE).div(price));
                payable(msg.sender).transfer(refundAmount);
            }
            emit SoldOut();
        }

        emit Received(msg.sender, amount);
    }

    /**
    * @dev Function to claim tokens to user, after release time, if project not reached softcap funds are returned back.
    */
    function claim() public returns (bool)  {
        // if sold out no need to wait for the time to finish, make sure liquidity is setup
        require(block.timestamp >= _end || (!_isSoldOut && _isLiquiditySetup), "LaunchpadToken: sales still going on");
        require(_balancesToClaim[msg.sender] > 0, "LaunchpadToken: No ETH to claim");
        require(_balancesToClaimTokens[msg.sender] > 0, "LaunchpadToken: No ETH to claim");
       // require(_isRefunded != false , "LaunchpadToken: Refunded is activated");
        uint256 amount =  _balancesToClaim[msg.sender];
        _balancesToClaim[msg.sender] = 0;
         uint256 amountTokens =  _balancesToClaimTokens[msg.sender];
        _balancesToClaimTokens[msg.sender] = 0;
        if(_isRefunded){
            // return back funds
            payable(msg.sender).transfer(amount);
            emit Refunded(msg.sender, amount);
        }
        else {
            // Transfer Tokens to User
            _token.safeTransfer(msg.sender, amountTokens);
            _claimedAmount = _claimedAmount.add(amountTokens);
            emit Claimed(msg.sender, amountTokens);            
        }
        return true;
    }

    /**
    * @dev Function to setup liquidity and transfer all amounts according to defined percents, if softcap not reached set Refunded flag.
    */
    function setupLiquidity() public onlyOwner {
        require(_isSoldOut == true || block.timestamp > _end , "LaunchpadToken: not sold out or time not elapsed yet" );
        require(_isRefunded == false, "Launchpad: refunded is activated");
        require(_isLiquiditySetup == false, "Setup has already been completed");
        _isLiquiditySetup = true;
        if(_raisedETH < _softCap){
            _isRefunded = true;
            return;
        }
        uint256 ethBalance = address(this).balance;
        require(ethBalance > 0, "LaunchpadToken: eth balance needs to be above zero" );
        uint256 liquidityAmount = ethBalance.mul(_liquidityPercent).div(_totalPercent);
        uint256 tokensAmount = _token.balanceOf(address(this));
        require(tokensAmount >= liquidityAmount.mul(_BASE_PRICE).div(_priceUniInv), "Launchpad: Not sufficient tokens amount");
        uint256 teamAmount = ethBalance.mul(_teamPercent).div(_totalPercent);
        uint256 layerFeeAmount = ethBalance.mul(_fee3).div(_totalPercent);
        uint256 supportFeeAmount = ethBalance.mul(_fee1).div(_totalPercent);
        uint256 stakeFeeAmount = ethBalance.mul(_fee1).div(_totalPercent);
        payable(_layerFeeAddress).transfer(layerFeeAmount);
        payable(_supportFeeAddress).transfer(supportFeeAmount);
        payable(_stakeFeeAddress).transfer(stakeFeeAmount);
        payable(_teamWallet).transfer(teamAmount);
        payable(_liquidityCreator).transfer(liquidityAmount);
        _token.safeTransfer(address(_liquidityCreator), liquidityAmount.mul(_BASE_PRICE).div(_priceUniInv));
    }

    /**
     * @notice Transfers non used tokens held by Lock to owner.
       @dev Able to withdraw funds after end time and liquidity setup, if refunded is enabled just let token owner 
       be able to withraw.
     */
    function release(IERC20 token) public onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        if(_isRefunded){
             token.safeTransfer(_owner, amount);
        }
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= _end || _isSoldOut == true, "Launchpad: current time is before release time");
        require(_isLiquiditySetup == true, "Launchpad: Liquidity is not setup");
        // TO Define: Tokens not claimed should go back to time after release time?
        require(_claimedAmount == _raisedETH || block.timestamp >= _releaseTime, "Launchpad: Tokens still to be claimed");
        require(amount > 0, "Launchpad: no tokens to release");

        token.safeTransfer(_owner, amount);
    }
    
    /**
    * @dev Function to append strings.
    * @param a - string a.
    * @param b - string b.
    * @param c - string c.
    * @param d - string d.
    * @param e - string e.
    * @return new string.
    */    
    function append(string memory a, string memory b, string memory c, string memory d, string memory e) internal pure returns (string memory) {
    return string(abi.encodePacked(a, b, c, d, e));
    }    
}
