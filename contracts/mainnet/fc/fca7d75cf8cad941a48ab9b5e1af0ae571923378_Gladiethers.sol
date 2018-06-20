pragma solidity ^0.4.20;

contract Gladiethers
{
    address public m_Owner;
    address public partner;

    mapping (address => uint) public gladiatorToPower; // gladiator power
    mapping (address => uint) public gladiatorToCooldown;
    mapping(address => uint) public gladiatorToQueuePosition;
    mapping(address => bool)  public trustedContracts;
    uint public m_OwnerFees = 0;
    address public kingGladiator;
    address public oraclizeContract;
    address[] public queue;
    
    bool started = false;


    event fightEvent(address indexed g1,address indexed g2,uint random,uint fightPower,uint g1Power);
    modifier OnlyOwnerAndContracts() {
        require(msg.sender == m_Owner ||  trustedContracts[msg.sender]);
        _;
    }
    function ChangeAddressTrust(address contract_address,bool trust_flag) public OnlyOwnerAndContracts() {
        require(msg.sender != contract_address);
        trustedContracts[contract_address] = trust_flag;
    }
    
    function Gladiethers() public{
        m_Owner = msg.sender;
    }
    
    function setPartner(address contract_partner) public OnlyOwnerAndContracts(){
        partner = contract_partner;
    }
    
    function setOraclize(address contract_oraclize) public OnlyOwnerAndContracts(){
        require(!started);
        oraclizeContract = contract_oraclize;
        started = true;
    }

    function joinArena() public payable returns (bool){

        require( msg.value >= 10 finney );

        if(queue.length > gladiatorToQueuePosition[msg.sender]){

            if(queue[gladiatorToQueuePosition[msg.sender]] == msg.sender){
                gladiatorToPower[msg.sender] += msg.value;
                return false;
            }
        }
        
        enter(msg.sender);
        return true;  

    }

    function enter(address gladiator) private{
        gladiatorToCooldown[gladiator] = now + 1 days;
        queue.push(gladiator);
        gladiatorToQueuePosition[gladiator] = queue.length - 1;
        gladiatorToPower[gladiator] += msg.value;
    }


    function remove(address gladiator) private returns(bool){
        
        if(queue.length > gladiatorToQueuePosition[gladiator]){

            if(queue[gladiatorToQueuePosition[gladiator]] == gladiator){ // is on the line ?
            
                queue[gladiatorToQueuePosition[gladiator]] = queue[queue.length - 1];
                gladiatorToQueuePosition[queue[queue.length - 1]] = gladiatorToQueuePosition[gladiator];
                gladiatorToCooldown[gladiator] =  9999999999999; // indicative number to know when it is in battle
                delete queue[queue.length - 1];
                queue.length = queue.length - (1);
                return true;
                
            }
           
        }
        return false;
        
        
    }

    function removeOrc(address _gladiator) public {
        require(msg.sender == oraclizeContract);
        remove(_gladiator);
    }

    function setCooldown(address gladiator, uint cooldown) internal{
        gladiatorToCooldown[gladiator] = cooldown;
    }

    function getGladiatorPower(address gladiator) public view returns (uint){
        return gladiatorToPower[gladiator];
    }
    
    function getQueueLenght() public view returns (uint){
        return queue.length;
    }

    function fight(address gladiator1,string _result) public {

        require(msg.sender == oraclizeContract);
        
        // in a unlikely case of 3 guys in queue two of them scheduleFight and the last one withdraws and left the first fighter that enconters the queue empty becomes the kingGladiator
        if(queue.length == 0){  
            gladiatorToCooldown[gladiator1] = now + 1 days;
            queue.push(gladiator1);
            gladiatorToQueuePosition[gladiator1] = queue.length - 1;
            kingGladiator = gladiator1;
        }else{
        
            uint indexgladiator2 = uint(sha3(_result)) % queue.length; // this is an efficient way to get the uint out in the [0, maxRange] range
            uint randomNumber = uint(sha3(_result)) % 1000;
            address gladiator2 = queue[indexgladiator2];
            
            require(gladiatorToPower[gladiator1] >= 10 finney && gladiator1 != gladiator2);
    
            
            uint g1chance = gladiatorToPower[gladiator1];
            uint g2chance =  gladiatorToPower[gladiator2];
            uint fightPower = SafeMath.add(g1chance,g2chance);
    
            g1chance = (g1chance*1000)/fightPower;
    
            if(g1chance <= 958){
                g1chance = SafeMath.add(g1chance,40);
            }else{
                g1chance = 998;
            }
    
            fightEvent( gladiator1, gladiator2,randomNumber,fightPower,gladiatorToPower[gladiator1]);
            uint devFee;
    
            if(randomNumber <= g1chance ){ // Wins the Attacker
                devFee = SafeMath.div(SafeMath.mul(gladiatorToPower[gladiator2],4),100);
    
                gladiatorToPower[gladiator1] =  SafeMath.add( gladiatorToPower[gladiator1], SafeMath.sub(gladiatorToPower[gladiator2],devFee) );
                queue[gladiatorToQueuePosition[gladiator2]] = gladiator1;
                gladiatorToQueuePosition[gladiator1] = gladiatorToQueuePosition[gladiator2];
                gladiatorToPower[gladiator2] = 0;
                gladiatorToCooldown[gladiator1] = now + 1 days; // reset atacker cooldown
    
                if(gladiatorToPower[gladiator1] > gladiatorToPower[kingGladiator] ){ // check if is the biggest guy in the arena
                    kingGladiator = gladiator1;
                }
    
            }else{
                //Defender Wins
                devFee = SafeMath.div(SafeMath.mul(gladiatorToPower[gladiator1],4),100);
    
                gladiatorToPower[gladiator2] = SafeMath.add( gladiatorToPower[gladiator2],SafeMath.sub(gladiatorToPower[gladiator1],devFee) );
                gladiatorToPower[gladiator1] = 0;
    
                if(gladiatorToPower[gladiator2] > gladiatorToPower[kingGladiator] ){
                    kingGladiator = gladiator2;
                }

        }

        
        gladiatorToPower[kingGladiator] = SafeMath.add( gladiatorToPower[kingGladiator],SafeMath.div(devFee,4) ); // gives 1%      (4% dead gladiator / 4 )
        m_OwnerFees = SafeMath.add( m_OwnerFees , SafeMath.sub(devFee,SafeMath.div(devFee,4)) ); // 4total - 1king  = 3%
        }
        
        

    }


    function withdraw(uint amount) public  returns (bool success){
        address withdrawalAccount;
        uint withdrawalAmount;

        // owner and partner can withdraw
        if (msg.sender == m_Owner || msg.sender == partner ) {
            withdrawalAccount = m_Owner;
            withdrawalAmount = m_OwnerFees;
            uint partnerFee = SafeMath.div(SafeMath.mul(withdrawalAmount,15),100);

            // set funds to 0
            m_OwnerFees = 0;

            if (!m_Owner.send(SafeMath.sub(withdrawalAmount,partnerFee))) revert(); // send to owner
            if (!partner.send(partnerFee)) revert(); // send to partner

            return true;
        }else{

            withdrawalAccount = msg.sender;
            withdrawalAmount = amount;

            // cooldown has been reached and the ammout i possible
            if(gladiatorToCooldown[msg.sender] < now && gladiatorToPower[withdrawalAccount] >= withdrawalAmount){

                gladiatorToPower[withdrawalAccount] = SafeMath.sub(gladiatorToPower[withdrawalAccount],withdrawalAmount);

                // gladiator have to be removed from areana if the power is less then 0.01 eth
                if(gladiatorToPower[withdrawalAccount] < 10 finney){
                    remove(msg.sender);
                }

            }else{
                return false;
            }

        }

        if (withdrawalAmount == 0) revert();

        // send the funds
        if (!msg.sender.send(withdrawalAmount)) revert();


        return true;
    }


}

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}