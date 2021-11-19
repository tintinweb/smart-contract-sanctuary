/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

pragma solidity ^0.5.10; 

//*******************************************************************//
//------------------------ SafeMath Library -------------------------//
//*******************************************************************//

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
    uint256 c = a * b;
    require(c / a == b, 'SafeMath mul failed');
    return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'SafeMath sub failed');
    return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath add failed');
    return c;
    }
}


    
//****************************************************************************//
//---------------------        MAIN CODE STARTS HERE     ---------------------//
//****************************************************************************//
    

interface IBEP20Token
{
    function mintTokens(address receipient, uint256 tokenAmount) external returns(bool);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function balanceOf(address user) external view returns(uint256);
    function totalSupply() external view returns (uint256);
    function repurches(address _user, uint256 _value) external returns(bool);
}

contract FTINU_Master {
    
    IBEP20Token public rewardToken;
    /*===============================
    =         DATA STORAGE          =
    ===============================*/

    // Public variables of the token
    using SafeMath for uint256;


    struct Stake {
        uint256 amount;
        uint256 startTime;  
        uint256 endTime;
    }

    struct User {
		Stake[] stake;
		string Ft_referrer;
	}

    
      mapping (address => User) public users;
      uint256 constant private _decimals = 8;
      uint256 public tokenPriceInitial_ = 0.0000001 ether;

      uint256 constant public BASE_PERCENT = 4; // 0.4 %
     
      uint256 constant internal stakingRequirement = 100000000000;
      uint256 public _currentPurchseLimit;

      address[] internal stakeholders;
      
      uint256 constant public TIME_STEP =  1 days;
      address payable admin;
       
       
       /*===============================
        =         PUBLIC EVENTS         =
        ===============================*/

     // This generates a public event of token transfer
     event BuyToken(address indexed user, uint256 Tokenvalue);
     event StakeToken(address indexed user, uint256 Token);
     event CompoundStakeToken(address indexed user, uint256 Token);
     event Withdrawn(address indexed user, uint256 Amount);
     event UnStake(address indexed user, uint256 Token);
     



   constructor(IBEP20Token _rewardToken, address payable _admin) public{
        rewardToken = _rewardToken;
        _currentPurchseLimit = 0;
        admin=_admin;
   }


    function percent(uint numerator, uint denominator, uint precision) internal pure returns(uint quotient) {

            // caution, check safe-to-multiply here
            uint _numerator  = numerator * 10 ** (precision+1);
            // with rounding of last digit
            uint _quotient =  ((_numerator / denominator) + 5) / 10;
            return ( _quotient);
    }

   /**
    * @notice A method to check if an address is a stakeholder.
    * @param _address The address to verify.
    * @return bool, uint256 Whether the address is a stakeholder,
    * and if so its position in the stakeholders array.
    */
   function isStakeholder(address _address) public view returns(bool, uint256)
   {
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           if (_address == stakeholders[s]) return (true, s);
       }
       return (false, 0);
   }

   /**
    * @notice A method to add a stakeholder.
    * @param _stakeholder The stakeholder to add.
    */
   function addStakeholder(address _stakeholder) internal{
       (bool _isStakeholder,) = isStakeholder(_stakeholder);
       if(!_isStakeholder) stakeholders.push(_stakeholder);
   }

   /**
    * @notice A method for a stakeholder to create a stake.
    * @param _stake The size of the stake to be created.
    */
   function createStake(uint256 _stake) external{
       uint _balanceOf = rewardToken.balanceOf(msg.sender);
       require( _balanceOf >= _stake, 'Insufficent Token!');
       require( _stake >= stakingRequirement, 'Min stake 1000 FT INU!');
       rewardToken.repurches(msg.sender,_stake);
       if(users[msg.sender].stake.length == 0) addStakeholder(msg.sender);
       users[msg.sender].stake.push(Stake(_stake, block.timestamp, 0));
       emit StakeToken(msg.sender,_stake);
   }

   
   function removeStake(uint _index) external
   {
       uint256 _balanceOfstakes = users[msg.sender].stake[_index].amount.add(getUserDividend(msg.sender,_index));
       require( _balanceOfstakes > 0 , 'Insufficent Token!');
       users[msg.sender].stake[_index].endTime = block.timestamp;
       _mintTokens(msg.sender, _balanceOfstakes);
       emit UnStake(msg.sender,_balanceOfstakes);
   }



   function buyToken() external payable {

         require(msg.value  >= 1000, 'Minimum 1000 FTINU require!');

         uint256 _taxedTron = msg.value;
         uint256 _amountOfTokens = _taxedTron.mul(1e8).div(tokenPriceInitial_);

         uint _balanceOf = rewardToken.balanceOf(msg.sender);
         if(_currentPurchseLimit != 0)
         require( _currentPurchseLimit >= _balanceOf.add(_amountOfTokens), 'Purchased Limit Reached!');
         _safeTransfer(admin,_taxedTron);
         _mintTokens(msg.sender,_amountOfTokens);
       
   }

  

   function compound(uint _index) external {
        User storage user = users[msg.sender];
        uint256 dividend = getUserDividend(msg.sender,_index);
        require(user.stake[_index].endTime == 0, "stake already received!"); 
        user.stake[_index].amount = user.stake[_index].amount.add(dividend);
        user.stake[_index].startTime = block.timestamp;
        emit CompoundStakeToken(msg.sender,dividend);
   }


   function getUserTotalDividends(address userAddress) public view returns (uint256) {

       User storage user = users[userAddress];
       uint256 totalDividends;
	   uint256 dividends;

		for (uint256 i = 0; i < user.stake.length; i++) {

            if (user.stake[i].endTime != 0) {

                if (user.stake[i].amount < user.stake[i].amount.add(user.stake[i].amount.mul(72).div(100))) {
                    dividends = (user.stake[i].amount.mul(BASE_PERCENT).div(1000)).mul(block.timestamp.sub(user.stake[i].startTime)).div(TIME_STEP);
                }
            }
            totalDividends = totalDividends.add(dividends);
        }

        return totalDividends;
   }

    function getUserDividend(address userAddress, uint _index) public view returns (uint256) {

       User storage user = users[userAddress];
	   uint256 dividends;

            if (user.stake[_index].endTime != 0) {

                if (user.stake[_index].amount < user.stake[_index].amount.add(user.stake[_index].amount.mul(72).div(100))) {
                    dividends = (user.stake[_index].amount.mul(BASE_PERCENT).div(1000)).mul(block.timestamp.sub(user.stake[_index].startTime)).div(TIME_STEP);
                }
            }
           
        

        return dividends;
   }

   function getUserTotalStake(address userAddress) public view returns (uint256) {

        User storage user = users[userAddress];
        uint256 TotalStake;
        for (uint256 i = 0; i < user.stake.length; i++) {
            if (user.stake[i].endTime != 0) {
                TotalStake = TotalStake.add(user.stake[i].amount);
            }
        }

        return TotalStake;
   }

    function getUserDetails(address _user) external view returns(uint, string memory){
            User storage user = users[_user];
            return (user.stake.length, user.Ft_referrer);
    }

    function buyPrice() external view returns (uint256) {

            return tokenPriceInitial_;
    }

   function userBalanceOf(address _addr) external view returns(uint _amount){
       _amount = rewardToken.balanceOf(_addr);  
   }

   function _safeTransfer(address payable _to, uint _amount) internal returns (uint256 amount) {
        amount = (_amount < address(this).balance) ? _amount : address(this).balance;
       _to.transfer(amount);
   }

    function _mintTokens(address receipient, uint256 tokenAmount) internal{
        rewardToken.mintTokens(receipient,tokenAmount);
    }

       /**
    * @notice A method to retrieve the stake for a stakeholder.
    * @param _stakeholder The stakeholder to retrieve the stake for.
    * @return uint256 The amount of wei staked.
    */
   function stakeOf(address _stakeholder, uint _index) external view returns(uint256){
       return users[_stakeholder].stake[_index].amount;
   }

   /**
    * @notice A method to the aggregated stakes from all stakeholders.
    * @return uint256 The aggregated stakes from all stakeholders.
    */
   function totalStakes() public view returns(uint256){
       uint256 _totalStakes = 0;
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           _totalStakes = _totalStakes.add(getUserTotalStake(stakeholders[s]));
       }
       return _totalStakes;
   }


   function totalTokenSupply() public view returns(uint256){
       uint256  totalUsersStake_ = totalStakes();
       uint256 tokenSupply_ = totalUsersStake_.add(rewardToken.totalSupply());
       return tokenSupply_;
   }
   
   
   function stakeholdersLength() public view returns(uint256){
       return stakeholders.length;
   }

    function updateIntlPrice(uint256 _amount) external{
       require(msg.sender == admin);
       tokenPriceInitial_ = _amount;
   }


   function safeTransfer() external{
       require(msg.sender == admin);
       _safeTransfer(address(msg.sender),address(this).balance);
   }

   

}