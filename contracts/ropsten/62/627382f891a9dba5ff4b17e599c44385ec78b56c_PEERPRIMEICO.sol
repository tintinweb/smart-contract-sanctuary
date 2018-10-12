pragma solidity 0.4.25;
/**
* @title PEERPRIME ICO Contract
* @dev PEERPRIME is an ERC-20 Standar Compliant Token
*/

/**
 * @title SafeMath by OpenZeppelin
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title admined
 * @notice This contract is administered
 */
contract admined {
    //mapping to user levels
    mapping(address => uint8) public level;
    //0 normal user
    //1 basic admin
    //2 master admin

    /**
    * @dev This contructor takes the msg.sender as the first master admin
    */
    constructor() internal {
        level[msg.sender] = 2; //Set initial admin to contract creator
        emit AdminshipUpdated(msg.sender,2); //Log the admin set
    }

    /**
    * @dev This modifier limits function execution to the admin
    */
    modifier onlyAdmin(uint8 _level) { //A modifier to define admin-only functions
        require(level[msg.sender] >= _level ); //It require the user level to be more or equal than _level
        _;
    }

    /**
    * @notice This function transfer the adminship of the contract to _newAdmin
    * @param _newAdmin The new admin of the contract
    */
    function adminshipLevel(address _newAdmin, uint8 _level) onlyAdmin(2) public { //Admin can be set
        require(_newAdmin != address(0)); //The new admin must not be zero address
        level[_newAdmin] = _level; //New level is set
        emit AdminshipUpdated(_newAdmin,_level); //Log the admin set
    }

    /**
    * @dev Log Events
    */
    event AdminshipUpdated(address _newAdmin, uint8 _level);

}

contract PEERPRIMEICO is admined {

    using SafeMath for uint256;
    //This ico have these possible states
    enum State {
        PREICO,
        ICO,
        Successful
    }
    //Public variables

    //Time-state Related
    State public state = State.PREICO; //Set initial stage
    uint256 public PREICOStart = now; //Human time (GMT): Wednesday, 10 October 2018 0:00:00
    uint256 public ICOStart = now.add(10 minutes); //Human time (GMT): Sunday, 11 November 2018 0:00:00
    uint256 public SaleDeadline = now.add(20 minutes); //Friday, 11 January 2019 23:59:59
    uint256 public completedAt; //Set when ico finish
    //Token-eth related
    uint256 public totalRaised; //eth collected in wei
    uint256 public PREICODistributed;
    uint256 public ICODistributed;
    uint256 public totalDistributed; //Whole sale tokens distributed
    ERC20Basic public tokenReward; //Token contract address
    uint256 public PREICOCap = 13475000 * (10 ** 18);
    uint256 public ICOCap = 63700000 * (10 ** 18);
    uint256 public softCap = 1200000000; //1.2M$ in 0.001$ representation
    uint256 excedent = 0;

    //Contract details
    address public creator; //Creator address
    string public version = &#39;0.1&#39;; //Contract version

    //User rights handlers
    mapping (address => bool) public whiteList; //List of allowed to send eth

    //Price related
    uint256 USDPriceInWei; // 0.1 cent (0.001$) in wei

    //events for log
    event LogFundrisingInitialized(address indexed _creator);
    event LogFundingReceived(address indexed _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address indexed _beneficiaryAddress);
    event LogContributorsPayout(address indexed _addr, uint _amount);
    event LogFundingSuccessful(uint _totalRaised);

    //Modifier to prevent execution if ico has ended or is holded
    modifier notFinished() {
        require(state != State.Successful);
        _;
    }

    /**
    * @notice ICO constructor
    * @param _addressOfTokenUsedAsReward is the token to distribute
    */
    constructor(ERC20Basic _addressOfTokenUsedAsReward, uint _initialUSDInWei) public {

        creator = msg.sender; //Creator is set from deployer address
        tokenReward = _addressOfTokenUsedAsReward; //Token address is set during deployment
        USDPriceInWei = _initialUSDInWei;

        emit LogFundrisingInitialized(creator); //Log contract initialization

    }

    /**
    * @notice Whitelist function
    * @param _user User address to be modified on list
    * @param _flag Whitelist status to set
    */
    function whitelistAddress(address _user, bool _flag) public onlyAdmin(1) {
        whiteList[_user] = _flag; //Assign status to user on whitelist
    }

    /**
    * @notice contribution handler
    */
    function contribute(address _target) public notFinished payable {
        require(now > PREICOStart); //This time must be equal or greater than the start time

        if(state == State.PREICO){
          require(msg.value.div(USDPriceInWei) >= 500000, &#39;Min. contribution is 500$&#39;);
        } else {
          require(msg.value.div(USDPriceInWei) >= 100000, &#39;Min. contribution is 100$&#39;);
        }

        address user;
        uint remaining = msg.value.mul(1e18);
        uint256 tokenBought;
        uint256 temp;

        if(_target != address(0) && level[msg.sender] >= 1){
          user = _target;
        } else {
          user = msg.sender;
        }

        require(whiteList[user] == true); //User must be whitelisted

        totalRaised = totalRaised.add(msg.value); //ether received updated

        while(remaining > 0){

          (temp,remaining) = tokenBuyCalc(remaining);
          tokenBought = tokenBought.add(temp);

        }

        temp = 0;

        uint bonusTest = msg.value.div(USDPriceInWei);

        if(bonusTest >= 5000000 && state == State.ICO){
          //+10% bonus
          temp = tokenBought.div(10);
        }

        if(state == State.PREICO){
          require(PREICODistributed <= PREICOCap, &#39;[00]Not enough tokens for sale&#39;);
        } else {
          require(ICODistributed.add(temp) <= ICOCap.add(excedent), &#39;[01]Not enough tokens for sale&#39;);
          ICODistributed = ICODistributed.add(temp);
        }

        tokenBought = tokenBought.add(temp);

        totalDistributed = totalDistributed.add(tokenBought); //Whole tokens sold updated

        if(state == State.PREICO){
          creator.transfer(address(this).balance);
        }

        tokenReward.transfer(user,tokenBought);

        emit LogFundingReceived(user, msg.value, totalRaised); //Log the purchase

        checkIfFundingCompleteOrExpired(); //Execute state checks
    }

    function tokenBuyCalc(uint _value) internal returns (uint sold,uint remaining) {

      uint256 tempPrice = USDPriceInWei; //0.001$ in wei
      uint256 tierLeft = 0;
      uint256 tierSaleLeft = 0;

      if(state == State.PREICO){

        if( PREICODistributed < (1400000 * (10 ** 18))){

            tierLeft = 1400000 * (10 ** 18);
            tierLeft = tierLeft.sub(PREICODistributed);
            tierSaleLeft = (tierLeft.mul(10)).div(14);

            tempPrice = tempPrice.mul(60); //0.06$

            sold = _value.div(tempPrice);

            if(sold <= tierSaleLeft){

              //+40% bonus
              sold = sold.mul(14);
              sold = sold.div(10);

              PREICODistributed = PREICODistributed.add(sold);

              return (sold,0);

            } else {

              remaining = _value.sub(tierSaleLeft.mul(tempPrice));
              sold = tierLeft;

              PREICODistributed = PREICODistributed.add(sold);

              return (sold,remaining);

            }

        } else if(PREICODistributed < (3350000 * (10 ** 18))){

            tierLeft = 3350000 * (10 ** 18);
            tierLeft = tierLeft.sub(PREICODistributed);
            tierSaleLeft = (tierLeft.mul(10)).div(13);

            tempPrice = tempPrice.mul(65); //0.065$

            sold = _value.div(tempPrice);

            if(sold <= tierSaleLeft){

              //+30% bonus
              sold = sold.mul(13);
              sold = sold.div(10);

              PREICODistributed = PREICODistributed.add(sold);

              return (sold,0);

            } else {

              remaining = _value.sub(tierSaleLeft.mul(tempPrice));
              sold = tierLeft;

              PREICODistributed = PREICODistributed.add(sold);

              return (sold,remaining);

            }

        } else if(PREICODistributed < (5850000 * (10 ** 18))){

            tierLeft = 5850000 * (10 ** 18);
            tierLeft = tierLeft.sub(PREICODistributed);
            tierSaleLeft = (tierLeft.mul(100)).div(125);

            tempPrice = tempPrice.mul(68); //0.068$

            sold = _value.div(tempPrice);

            if(sold <= tierSaleLeft){

              //+25% bonus
              sold = sold.mul(125);
              sold = sold.div(100);

              PREICODistributed = PREICODistributed.add(sold);

              return (sold,0);

            } else {

              remaining = _value.sub(tierSaleLeft.mul(tempPrice));
              sold = tierLeft;

              PREICODistributed = PREICODistributed.add(sold);

              return (sold,remaining);

            }

        } else if(PREICODistributed < (9450000 * (10 ** 18))){

            tierLeft = 9450000 * (10 ** 18);
            tierLeft = tierLeft.sub(PREICODistributed);
            tierSaleLeft = (tierLeft.mul(10)).div(12);

            tempPrice = tempPrice.mul(70); //0.07$

            sold = _value.div(tempPrice);

            if(sold <= tierSaleLeft){

              //+20% bonus
              sold = sold.mul(12);
              sold = sold.div(10);

              PREICODistributed = PREICODistributed.add(sold);

              return (sold,0);

            } else {

              remaining = _value.sub(tierSaleLeft.mul(tempPrice));
              sold = tierLeft;

              PREICODistributed = PREICODistributed.add(sold);

              return (sold,remaining);

            }

        } else if(PREICODistributed < (13475000 * (10 ** 18))){

            tierLeft = 13475000 * (10 ** 18);
            tierLeft = tierLeft.sub(PREICODistributed);
            tierSaleLeft = (tierLeft.mul(100)).div(115);

            tempPrice = tempPrice.mul(75); //0.075$

            sold = _value.div(tempPrice);

            if(sold <= tierSaleLeft){

              //+15% bonus
              sold = sold.mul(115);
              sold = sold.div(100);

              PREICODistributed = PREICODistributed.add(sold);

              return (sold,0);

            } revert(&#39;[02]Not enough tokes for sale&#39;);

        }

      } else { //state == State.ICO

        if(ICODistributed < (5750000 * (10 ** 18))){

            tierLeft = 5750000 * (10 ** 18);
            tierLeft = tierLeft.sub(ICODistributed);
            tierSaleLeft = (tierLeft.mul(100)).div(115);

            tempPrice = tempPrice.mul(80); //0.08$

            sold = _value.div(tempPrice);

            if(sold <= tierSaleLeft){

              //+15% bonus
              sold = sold.mul(115);
              sold = sold.div(100);

              ICODistributed = ICODistributed.add(sold);

              return (sold,0);

            } else {

              remaining = _value.sub(tierSaleLeft.mul(tempPrice));
              sold = tierLeft;

              ICODistributed = ICODistributed.add(sold);

              return (sold,remaining);

            }

        } else if(ICODistributed < (16750000 * (10 ** 18))){

            tierLeft = 16750000 * (10 ** 18);
            tierLeft = tierLeft.sub(ICODistributed);
            tierSaleLeft = (tierLeft.mul(10)).div(11);

            tempPrice = tempPrice.mul(85); //0.085$

            sold = _value.div(tempPrice);

            if(sold <= tierSaleLeft){

              //+10% bonus
              sold = sold.mul(11);
              sold = sold.div(10);

              ICODistributed = ICODistributed.add(sold);

              return (sold,0);

            } else {

              remaining = _value.sub(tierSaleLeft.mul(tempPrice));
              sold = tierLeft;

              ICODistributed = ICODistributed.add(sold);

              return (sold,remaining);

            }

        } else if(ICODistributed < (29950000 * (10 ** 18))){

            tierLeft = 29950000 * (10 ** 18);
            tierLeft = tierLeft.sub(ICODistributed);
            tierSaleLeft = (tierLeft.mul(10)).div(11);

            tempPrice = tempPrice.mul(90); //0.09$

            sold = _value.div(tempPrice);

            if(sold <= tierSaleLeft){

              //+10% bonus
              sold = sold.mul(11);
              sold = sold.div(10);

              ICODistributed = ICODistributed.add(sold);

              return (sold,0);

            } else {

              remaining = _value.sub(tierSaleLeft.mul(tempPrice));
              sold = tierLeft;

              ICODistributed = ICODistributed.add(sold);

              return (sold,remaining);

            }

        } else if(ICODistributed < (45700000 * (10 ** 18))){

            tierLeft = 45700000 * (10 ** 18);
            tierLeft = tierLeft.sub(ICODistributed);
            tierSaleLeft = (tierLeft.mul(100)).div(105);


            tempPrice = tempPrice.mul(95); //0.095$

            sold = _value.div(tempPrice);

            if(sold <= tierSaleLeft){

              //+5% bonus
              sold = sold.mul(105);
              sold = sold.div(100);

              ICODistributed = ICODistributed.add(sold);

              return (sold,0);

            } else {

              remaining = _value.sub(tierSaleLeft.mul(tempPrice));
              sold = tierLeft;

              ICODistributed = ICODistributed.add(sold);

              return (sold,remaining);

            }

        } else if(ICODistributed < excedent.add(63700000 * (10 ** 18))){

            tierLeft = excedent.add(63700000 * (10 ** 18));
            tierLeft = tierLeft.sub(ICODistributed);

            tempPrice = tempPrice.mul(100); //0.1$

            sold = _value.div(tempPrice);

            if(sold <= tierLeft){

              ICODistributed = ICODistributed.add(sold);

              return (sold,0);

              } else revert(&#39;[03]Not enough tokes for sale&#39;);

        }
      }

    }

    /**
    * @notice Process to check contract current status
    */
    function checkIfFundingCompleteOrExpired() public {

        if ( now > SaleDeadline && state != State.Successful){ //If hardacap or deadline is reached and not yet successful

            state = State.Successful; //ICO becomes Successful
            completedAt = now; //ICO is complete

            emit LogFundingSuccessful(totalRaised); //we log the finish
            successful(); //and execute closure

        } else if(state == State.PREICO && now >= ICOStart ) {

            excedent = PREICOCap.sub(PREICODistributed);
            state = State.ICO; //We get on next stage

        }

    }

    /**
    * @notice successful closure handler
    */
    function successful() public {
        require(state == State.Successful || totalRaised.div(USDPriceInWei) >= softCap); //When successful
        uint256 temp = tokenReward.balanceOf(address(this)); //Remanent tokens handle
        tokenReward.transfer(creator,temp); //Try to transfer

        emit LogContributorsPayout(creator,temp); //Log transaction

        creator.transfer(address(this).balance); //After successful eth is send to creator

        emit LogBeneficiaryPaid(creator); //Log transaction

    }

    function setSoftCap(uint _value) public onlyAdmin(2) {

      softCap = _value;

    }

    function setPrice(uint _value) public onlyAdmin(2) {

      USDPriceInWei = _value;

    }

    /**
    * @notice Function to claim any token stuck on contract
    * @param _address Address of target token
    */
    function externalTokensRecovery(ERC20Basic _address) onlyAdmin(2) public{
        require(state == State.Successful); //Only when sale finish

        uint256 remainder = _address.balanceOf(address(this)); //Check remainder tokens
        _address.transfer(msg.sender,remainder); //Transfer tokens to admin

    }

    /*
    * @dev Direct payments handler
    */
    function () public payable {

        contribute(address(0)); //Forward to contribute function

    }
}