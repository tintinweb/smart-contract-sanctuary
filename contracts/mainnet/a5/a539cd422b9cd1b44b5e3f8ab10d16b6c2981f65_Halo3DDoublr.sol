pragma solidity ^0.4.21;

/**
 *
 *
 *
 * ATTENTION!
 *
 *  HALO3D token machine!
 */

contract ERC20Interface {
    function transfer(address to, uint256 tokens) public returns (bool success);
}

contract Halo3D {

    function buy(address) public payable returns(uint256);
    function transfer(address, uint256) public returns(bool);
    function withdraw() public;
    function myTokens() public view returns(uint256);
    function myDividends(bool) public view returns(uint256);
    function reinvest() public;
}

/**
 * Definition of contract accepting Halo3D tokens
 * Games, casinos, anything can reuse this contract to support Halo3D tokens
 */
contract AcceptsHalo3D {
    Halo3D public tokenContract;

    function AcceptsHalo3D(address _tokenContract) public {
        tokenContract = Halo3D(_tokenContract);
    }

    modifier onlyTokenContract {
        require(msg.sender == address(tokenContract));
        _;
    }

    /**
    * @dev Standard ERC677 function that will handle incoming token transfers.
    *
    * @param _from  Token sender address.
    * @param _value Amount of tokens.
    * @param _data  Transaction metadata.
    */
    function tokenFallback(address _from, uint256 _value, bytes _data) external returns (bool);
}

contract Owned {
    address public owner;
    address public ownerCandidate;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        ownerCandidate = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == ownerCandidate);
        owner = ownerCandidate;
    }

}

contract Halo3DDoublr is Owned, AcceptsHalo3D {

    /**
     * Events
     */
    event Deposit(uint256 amount, address depositer);
    event Payout(uint256 amount, address creditor);

    /**
     * Structs
     */
    struct Participant {
        address etherAddress;
        uint256 payout;
    }

    //Total ETH managed over the lifetime of the contract
    uint256 throughput;
    //Total ETH received from dividends
    uint256 dividends;
    //The percent to return to depositers. 100 for 00%, 200 to double, etc.
    uint256 public multiplier;
    //Where in the line we are with creditors
    uint256 public payoutOrder = 0;
    //How much is owed to people
    uint256 public backlog = 0;
    //The creditor line
    Participant[] public participants;
    //How much each person is owed
    mapping(address => uint256) public creditRemaining;


    /**
     * Constructor
     */
    function Halo3DDoublr(uint multiplierPercent, address _baseContract)
      AcceptsHalo3D(_baseContract)
      public {
        multiplier = multiplierPercent;
    }


    /**
     * Fallback function for the contract, protect investors
     */
    function() payable public {
      // Not accepting Ether directly
    }

    /**
    * Deposit Halo3D tokens to get in line to be credited back the multiplier as percent.
    * This function can be called only via Halo3D contract using function
    * Halo3D.transferAndCall(address, uint256, bytes)
    *
    * @dev Standard ERC677 function that will handle incoming token transfers.
    * @param _from  Token sender address.
    * @param _value Amount of tokens.
    * @param _data  Transaction metadata.
    */
    function tokenFallback(address _from, uint256 _value, bytes _data)
      external
      onlyTokenContract
      returns (bool) {
        require(!_isContract(_from));
        require(_value <= 100 ether); // 100 H3D tokens
        require(_value >= 1 ether); // 1 H3D token
        //Compute how much to pay them
        uint256 amountCredited = (_value * multiplier) / 100;
        //Get in line to be paid back.
        participants.push(Participant(_from, amountCredited));
        //Increase the backlog by the amount owed
        backlog += amountCredited;
        //Increase the amount owed to this address
        creditRemaining[_from] += amountCredited;
        //Emit a deposit event.
        emit Deposit(_value, _from);

        //Increase our total throughput
        throughput += _value;

        uint balance = _value;

        //While we still have money to send
        reinvest(); // protect from people sending tokens to contract
        while (balance > 0) {
            //Either pay them what they are owed or however much we have, whichever is lower.
            uint payoutToSend = balance < participants[payoutOrder].payout ? balance : participants[payoutOrder].payout;
            //if we have something to pay them
            if(payoutToSend > 0){
                //subtract how much we&#39;ve spent
                balance -= payoutToSend;
                //subtract the amount paid from the amount owed
                backlog -= payoutToSend;
                //subtract the amount remaining they are owed
                creditRemaining[participants[payoutOrder].etherAddress] -= payoutToSend;
                //credit their account the amount they are being paid
                participants[payoutOrder].payout -= payoutToSend;

                //Try and pay them, making best effort. But if we fail? Run out of gas? That&#39;s not our problem any more
                if(tokenContract.transfer(participants[payoutOrder].etherAddress, payoutToSend)) {
                  //Record that they were paid
                  emit Payout(payoutToSend, participants[payoutOrder].etherAddress);
                }else{
                    //undo the accounting, they are being skipped because they are not payable.
                    balance += payoutToSend;
                    backlog += payoutToSend;
                    creditRemaining[participants[payoutOrder].etherAddress] += payoutToSend;
                    participants[payoutOrder].payout += payoutToSend;
                }

            }
            //If we still have balance left over
            if(balance > 0){
                // go to the next person in line
                payoutOrder += 1;
            }
            //If we&#39;ve run out of people to pay, stop
            if(payoutOrder >= participants.length){
                return true;
            }
        }

        return true;
    }

    function _isContract(address _user) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(_user) }
        return size > 0;
    }

    // Reinvest Halo3D Doublr dividends
    // All the dividends this contract makes will be used to grow token fund for players
    function reinvest() public {
       if(tokenContract.myDividends(true) > 1) {
         tokenContract.reinvest();
       }
    }

    /**
     * Number of participants who are still owed.
     */
    function backlogLength() public view returns (uint256){
        return participants.length - payoutOrder;
    }

    /**
     * Total amount still owed in credit to depositors.
     */
    function backlogAmount() public view returns (uint256){
        return backlog;
    }

    /**
     * Total number of deposits in the lifetime of the contract.
     */
    function totalParticipants() public view returns (uint256){
        return participants.length;
    }

    /**
     * Total amount of Halo3D that the contract has delt with so far.
     */
    function totalSpent() public view returns (uint256){
        return throughput;
    }

    /**
     * Amount still owed to an individual address
     */
    function amountOwed(address anAddress) public view returns (uint256) {
        return creditRemaining[anAddress];
    }

     /**
      * Amount owed to this person.
      */
    function amountIAmOwed() public view returns (uint256){
        return amountOwed(msg.sender);
    }
}