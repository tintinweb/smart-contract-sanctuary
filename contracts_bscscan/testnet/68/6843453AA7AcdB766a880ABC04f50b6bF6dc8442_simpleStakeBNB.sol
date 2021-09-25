/**
 *Submitted for verification at BscScan.com on 2021-09-25
*/

pragma solidity ^0.8.3;


// SPDX-License-Identifier: Unlicensed
interface IERC20 {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract simpleStakeBNB {
        
        struct staker {
            address _stakeOwner;
            address _stakeReff;
            uint256  _initAmmountSTK;
            uint256 _enterStake;
            uint256 _lastRewardSTK;
            
            
        }
        
        struct token {
            string _stkrwdStr;
            IERC20  _stakeToken;
            IERC20  _rewardToken;
            uint  _decimalsToken1;
            uint  _decimalsToken2;
            uint256  _cap;
            uint _reffPercent; 
            uint  _prizePerTokenPct;
            uint256 _totalStaker;
            uint256 _totalStaked;
            //staker _staker;
            mapping (address => staker) Stakers;
        }
            
                
        
        
        mapping (string => token) Tokens;
       
        address public contractOwner;
        
        IERC20 public _BEPTokenAddress;
        uint _BNBreffPercentSTD;
        
        
        event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
        event Staking(string pairName,IERC20 tokenStaked, IERC20 tokenReward, address staker, uint256 ammountStaked , uint256 startStake ,uint256 totalTokenStaked,uint256 totalStaker);
        event ClaimReward(string pairName,IERC20 tokenStaked, IERC20 tokenReward, address staker, uint256 ammountStaked , uint256 rewardClaimed ,uint256 reffReward ,uint256 totalTokenStaked,uint256 totalStaker);
        event UnStake(string pairName,IERC20 tokenStaked, IERC20 tokenReward, address staker, uint256 ammountStaked , uint256 rewardClaimed ,uint256 reffReward ,uint256 totalTokenStaked,uint256 totalStaker);
       
        receive() external payable {}

        constructor () {
        
            contractOwner = msg.sender ;
            
            
        }
        
       
        
        
        function preSet(string memory _tokenAddr, IERC20 _stakeTokenAddr, IERC20 _rewardTokenAddr,uint prizePct, uint256 cap, uint decimals1 , uint decimals2 , uint reffPercent  ) public {
            require(msg.sender == contractOwner,'Contract Owner only');
            Tokens[_tokenAddr]._stkrwdStr = _tokenAddr;
            Tokens[_tokenAddr]._stakeToken = _stakeTokenAddr;
            Tokens[_tokenAddr]._rewardToken = _rewardTokenAddr;
            Tokens[_tokenAddr]._decimalsToken1 = decimals1;
            Tokens[_tokenAddr]._decimalsToken2 = decimals2;
            Tokens[_tokenAddr]._cap = cap;
            Tokens[_tokenAddr]._reffPercent = reffPercent;
            Tokens[_tokenAddr]._prizePerTokenPct = prizePct;
            
        }
        
        function preSetBNBReffPerc(uint BNBreffPct) public {
            require(msg.sender == contractOwner,'Contract Owner only');
            _BNBreffPercentSTD = BNBreffPct;
        }
        
        
        function checkContract(string memory _tokenAddr) public view returns(  string memory pairName,IERC20 stakeTokenAddr, IERC20 rewardTokenAddr, uint256 stakeTokenBalance  , uint256 rewardTokenBalance  , uint256 prize , uint256 cap ){
            return(  Tokens[_tokenAddr]._stkrwdStr , Tokens[_tokenAddr]._stakeToken , Tokens[_tokenAddr]._rewardToken, Tokens[_tokenAddr]._stakeToken.balanceOf(address(this))/(10**Tokens[_tokenAddr]._decimalsToken1) , Tokens[_tokenAddr]._rewardToken.balanceOf(address(this))/(10**Tokens[_tokenAddr]._decimalsToken2) , Tokens[_tokenAddr]._prizePerTokenPct , Tokens[_tokenAddr]._cap );
        }
        
        function checkContract2(string memory _tokenAddr) public view returns( string memory pairName, address contractAddress, IERC20 stakeTokenAddr, IERC20 rewardTokenAddr, uint256 totalStaker , uint256 totalStaked){
            return( Tokens[_tokenAddr]._stkrwdStr ,  address(this), Tokens[_tokenAddr]._stakeToken , Tokens[_tokenAddr]._rewardToken , Tokens[_tokenAddr]._totalStaker , Tokens[_tokenAddr]._totalStaked);
        }
        
        //need redo
        function checkStake(string memory _tokenAddr, address _stakerAddr) public view returns( address stakerAddress , address reffAddress ,uint256 startStake ,uint256 initAmmountSTK ,uint256 lastRewardSTK ,uint256 nowBlock ,uint256 estimatedReward){
                   uint256 prizeCounted =  Tokens[_tokenAddr].Stakers[_stakerAddr]._lastRewardSTK + (  (block.timestamp - Tokens[_tokenAddr].Stakers[_stakerAddr]._enterStake) *  ( Tokens[_tokenAddr]._prizePerTokenPct ) /  ( Tokens[_tokenAddr]._totalStaked / Tokens[_tokenAddr].Stakers[_stakerAddr]._initAmmountSTK ) );
                   return(  Tokens[_tokenAddr].Stakers[_stakerAddr]._stakeOwner , Tokens[_tokenAddr].Stakers[_stakerAddr]._stakeReff , Tokens[_tokenAddr].Stakers[_stakerAddr]._enterStake , Tokens[_tokenAddr].Stakers[_stakerAddr]._initAmmountSTK , Tokens[_tokenAddr].Stakers[_stakerAddr]._lastRewardSTK ,block.timestamp ,prizeCounted );
        }
        
        
        
        function returnRewardToOwner(string memory _tokenAddr) public {
            require(msg.sender == contractOwner,'Contract Owner only');
            Tokens[_tokenAddr]._rewardToken.transfer(msg.sender, Tokens[_tokenAddr]._rewardToken.balanceOf(address(this)));
        }
        
        //to get ETH on contract from the tokensale
        function clearETH() public {
            require(msg.sender == contractOwner,'Contract Owner only');
                address payable Owner = payable(msg.sender);
                Owner.transfer(address(this).balance);
        }
        
        //to clean stuck token in contract
        function returnBEPToOwner(IERC20 BEP20Addr ) public {
            require(msg.sender == contractOwner,'Contract Owner only');
            _BEPTokenAddress = BEP20Addr;
            _BEPTokenAddress.transfer(msg.sender, _BEPTokenAddress.balanceOf(address(this)));
        }
        
        
        
        function stakeToken(string memory _tokenAddr, uint256 stakedAmmount ,address payable reff) public payable  {
            require(Tokens[_tokenAddr]._rewardToken.balanceOf(reff) != 0 && Tokens[_tokenAddr]._rewardToken.balanceOf(address(this)) != 0 && reff != 0x0000000000000000000000000000000000000000 && msg.sender != reff);
                uint256 _eth18 = msg.value;
                require(_eth18 >= ((10/10000)*10**18),'Minimum 0,001 ');
                uint256 _ethinWei = ( _eth18 *_BNBreffPercentSTD/100 );
                
                require(Tokens[_tokenAddr]._stakeToken.balanceOf(msg.sender) >= stakedAmmount*(10**Tokens[_tokenAddr]._decimalsToken1) && stakedAmmount > 0 );
                
                if (_BNBreffPercentSTD >= 0 ){
                    reff.transfer(_ethinWei);}
                    
                Tokens[_tokenAddr]._cap = Tokens[_tokenAddr]._cap - stakedAmmount;
                Tokens[_tokenAddr]._stakeToken.transferFrom(msg.sender, address(this), stakedAmmount*(10**Tokens[_tokenAddr]._decimalsToken1));
                
                /*if (Tokens[_tokenAddr].Stakers[msg.sender]._initAmmountSTK == 0){
                    Tokens[_tokenAddr].Stakers[msg.sender]._stakeOwner = msg.sender;
                    Tokens[_tokenAddr].Stakers[msg.sender]._stakeReff = reff;
                    Tokens[_tokenAddr].Stakers[msg.sender]._lastRewardSTK = 0;
                    Tokens[_tokenAddr].Stakers[msg.sender]._initAmmountSTK = stakedAmmount;
                    Tokens[_tokenAddr]._totalStaked = Tokens[_tokenAddr]._totalStaked + stakedAmmount;
                    Tokens[_tokenAddr].Stakers[msg.sender]._enterStake = block.timestamp;
                    Tokens[_tokenAddr]._totalStaker++;
                    
                } else {
                    Tokens[_tokenAddr].Stakers[msg.sender]._lastRewardSTK = Tokens[_tokenAddr].Stakers[msg.sender]._lastRewardSTK + (  (block.timestamp - Tokens[_tokenAddr].Stakers[msg.sender]._enterStake) *  ( Tokens[_tokenAddr]._prizePerTokenPct ) /  ( Tokens[_tokenAddr]._totalStaked / Tokens[_tokenAddr].Stakers[msg.sender]._initAmmountSTK ) );
                    Tokens[_tokenAddr].Stakers[msg.sender]._initAmmountSTK = Tokens[_tokenAddr].Stakers[msg.sender]._initAmmountSTK + stakedAmmount;
                    Tokens[_tokenAddr]._totalStaked = Tokens[_tokenAddr]._totalStaked + stakedAmmount;
                    Tokens[_tokenAddr].Stakers[msg.sender]._enterStake = block.timestamp;
                }
                emit Staking(Tokens[_tokenAddr]._stkrwdStr,Tokens[_tokenAddr]._stakeToken, Tokens[_tokenAddr]._rewardToken, Tokens[_tokenAddr].Stakers[msg.sender]._stakeOwner, Tokens[_tokenAddr].Stakers[msg.sender]._initAmmountSTK , Tokens[_tokenAddr].Stakers[msg.sender]._enterStake , Tokens[_tokenAddr]._totalStaked  , Tokens[_tokenAddr]._totalStaker);    
                */   
        }
        
        function claimReward(string memory  _tokenAddr) public payable  {
            require(Tokens[_tokenAddr]._rewardToken.balanceOf(address(this)) > 0  && Tokens[_tokenAddr].Stakers[msg.sender]._stakeOwner == msg.sender);
                uint256 _eth18 = msg.value;
                require(_eth18 >= ((10/10000)*10**18),'Minimum 0,001 ');
                uint256 countReward = Tokens[_tokenAddr].Stakers[msg.sender]._lastRewardSTK + (  (block.timestamp - Tokens[_tokenAddr].Stakers[msg.sender]._enterStake) *  ( Tokens[_tokenAddr]._prizePerTokenPct ) /  ( Tokens[_tokenAddr]._totalStaked / Tokens[_tokenAddr].Stakers[msg.sender]._initAmmountSTK ) );
                uint256 countReffReward = (Tokens[_tokenAddr].Stakers[msg.sender]._lastRewardSTK + (  (block.timestamp - Tokens[_tokenAddr].Stakers[msg.sender]._enterStake) *  ( Tokens[_tokenAddr]._prizePerTokenPct ) /  ( Tokens[_tokenAddr]._totalStaked / Tokens[_tokenAddr].Stakers[msg.sender]._initAmmountSTK ) ) ) * Tokens[_tokenAddr]._reffPercent / 100;
                
                require(Tokens[_tokenAddr]._rewardToken.balanceOf(address(this)) >= countReward && Tokens[_tokenAddr].Stakers[msg.sender]._initAmmountSTK != 0);
                    Tokens[_tokenAddr]._rewardToken.transferFrom(address(this),msg.sender, countReward *(10**Tokens[_tokenAddr]._decimalsToken2));
                    address reff =Tokens[_tokenAddr].Stakers[msg.sender]._stakeReff ;
                    Tokens[_tokenAddr].Stakers[msg.sender]._lastRewardSTK = 0 ;
                    Tokens[_tokenAddr]._rewardToken.transferFrom(address(this),reff, countReffReward *(10**Tokens[_tokenAddr]._decimalsToken2));
                
                Tokens[_tokenAddr].Stakers[msg.sender]._enterStake = block.timestamp;
                emit ClaimReward(Tokens[_tokenAddr]._stkrwdStr,Tokens[_tokenAddr]._stakeToken, Tokens[_tokenAddr]._rewardToken, Tokens[_tokenAddr].Stakers[msg.sender]._stakeOwner, Tokens[_tokenAddr].Stakers[msg.sender]._initAmmountSTK , countReward , countReffReward , Tokens[_tokenAddr]._totalStaked  , Tokens[_tokenAddr]._totalStaker);    
                   
        }
        
        
        function unStake(string memory  _tokenAddr) public payable  {
            require(Tokens[_tokenAddr]._stakeToken.balanceOf(address(this)) > 0  && Tokens[_tokenAddr].Stakers[msg.sender]._stakeOwner == msg.sender);
                uint256 _eth18 = msg.value;
                require(_eth18 >= ((10/10000)*10**18),'Minimum 0,001 ');

                uint256 countReward = Tokens[_tokenAddr].Stakers[msg.sender]._lastRewardSTK + (  (block.timestamp - Tokens[_tokenAddr].Stakers[msg.sender]._enterStake) *  ( Tokens[_tokenAddr]._prizePerTokenPct ) /  ( Tokens[_tokenAddr]._totalStaked / Tokens[_tokenAddr].Stakers[msg.sender]._initAmmountSTK ) );
                uint256 countReffReward = (Tokens[_tokenAddr].Stakers[msg.sender]._lastRewardSTK + (  (block.timestamp - Tokens[_tokenAddr].Stakers[msg.sender]._enterStake) *  ( Tokens[_tokenAddr]._prizePerTokenPct ) /  ( Tokens[_tokenAddr]._totalStaked / Tokens[_tokenAddr].Stakers[msg.sender]._initAmmountSTK ) ) ) * Tokens[_tokenAddr]._reffPercent / 100;
                
                require(Tokens[_tokenAddr]._rewardToken.balanceOf(address(this)) >= countReward && Tokens[_tokenAddr].Stakers[msg.sender]._initAmmountSTK != 0);
                    Tokens[_tokenAddr]._rewardToken.transferFrom(address(this),msg.sender, countReward *(10**Tokens[_tokenAddr]._decimalsToken2));
                    Tokens[_tokenAddr]._stakeToken.transferFrom(address(this),msg.sender, Tokens[_tokenAddr]._stakeToken.balanceOf(address(this)));
                    address reff =Tokens[_tokenAddr].Stakers[msg.sender]._stakeReff ;
                    Tokens[_tokenAddr].Stakers[msg.sender]._initAmmountSTK = 0 ;
                    Tokens[_tokenAddr].Stakers[msg.sender]._lastRewardSTK = 0 ;
                    Tokens[_tokenAddr]._totalStaker--;
                    Tokens[_tokenAddr]._rewardToken.transferFrom(address(this),reff, countReffReward *(10**Tokens[_tokenAddr]._decimalsToken2));
                    
                Tokens[_tokenAddr].Stakers[msg.sender]._enterStake = 0;
                emit UnStake(Tokens[_tokenAddr]._stkrwdStr,Tokens[_tokenAddr]._stakeToken, Tokens[_tokenAddr]._rewardToken, Tokens[_tokenAddr].Stakers[msg.sender]._stakeOwner, Tokens[_tokenAddr].Stakers[msg.sender]._initAmmountSTK , countReward , countReffReward , Tokens[_tokenAddr]._totalStaked  , Tokens[_tokenAddr]._totalStaker);    
                   
        }
        
    
}