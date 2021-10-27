/**
 *Submitted for verification at polygonscan.com on 2021-10-26
*/

pragma solidity 0.5.10; /*

___________________________________________________________________
  _      _                                        ______           
  |  |  /          /                                /              
--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
  |/ |/    /___) /   /   ' /   ) / /  ) /___)     /      /   )     
__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_





=== 'Dithereum' Bridge contract with following features ===
    => Fires event against paid coin to track and trigger action in dithereum chain
    => Swaps coin back for reqduest made on dithereum chain

============= Independant Audit of the code ============
    => Multiple Freelancers Auditors
    => Community Audit by Bug Bounty program


-------------------------------------------------------------------
 Copyright (c) 2020 onwards EtherAuthority Inc. ( https://EtherAuthority.io )
 Contract designed with ❤ by EtherAuthority ( https://EtherAuthority.io )
-------------------------------------------------------------------
*/ 




//*******************************************************************//
//------------------------ SafeMath Library -------------------------//
//*******************************************************************//
/**
    * @title SafeMath
    * @dev Math operations with safety checks that throw on error
    */
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


//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
contract owned
{
    address internal owner;
    address internal newOwner;
    address public signer;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        signer = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    modifier onlySigner {
        require(msg.sender == signer, 'caller must be signer');
        _;
    }


    function changeSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //the reason for this flow is to protect owners from sending ownership to unintended address due to human error
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}



    
//****************************************************************************//
//---------------------        MAIN CODE STARTS HERE     ---------------------//
//****************************************************************************//
    
contract diethereumBridge is owned {
    
    // user => coinAmount => timeOfRequest => 
    mapping(address => mapping(uint => mapping(uint => uint))) public swapStatus; // 0 = null, 1 = pending, 2 = processing, 3 = processed


    // This generates a public event of coin received by contract
    event coinReceivedEv(address indexed from, uint256 value);

   // This generates a public event of coin sent by contract
    event returnCoinEv(address indexed to, uint256 value, uint256 timeOfEvent);

   // Just a record of coin swap done
    event swapProcessedEv(address user,uint amount,uint timeOfEvent);
    
    function () external payable {
      require(msg.value > 0, "zero coin sent");
      uint payTime = now;
      swapStatus[msg.sender][msg.value][payTime] = 1; 
      emit coinReceivedEv(msg.sender, msg.value);
    }

    function swapMyCoin() external payable returns(bool){
      require(msg.value > 0, "zero coin sent");
      uint payTime = now;
      swapStatus[msg.sender][msg.value][payTime] = 1;      
      emit coinReceivedEv(msg.sender, msg.value);
      return true;
    }


    function swapProcessing(address _user, uint _amount, uint timeOfRequest) public onlySigner returns(bool)
    {
        require(swapStatus[_user][_amount][timeOfRequest] == 1, "invalid input");
        swapStatus[msg.sender][_amount][timeOfRequest] = 2;
        return true;
    }

    function swapCompleted(address _user, uint _amount, uint timeOfRequest) public onlySigner returns(bool)
    {
        require(swapStatus[_user][_amount][timeOfRequest] == 2, "invalid input");
        swapStatus[_user][_amount][timeOfRequest] = 3;
        emit swapProcessedEv(_user, _amount, now);
        return true;
    }

    function swapReverted(address _user, uint _amount, uint timeOfRequest) public onlySigner returns(bool)
    {
        require(swapStatus[_user][_amount][timeOfRequest] == 2, "invalid input");
        swapStatus[_user][_amount][timeOfRequest] = 1;
        return true;
    }


    function returnCoin(address payable _user, uint _amount) public onlySigner returns(bool)
    {
        _user.transfer(_amount);       
        emit returnCoinEv(_user, _amount, now);
        return true;
    }


}