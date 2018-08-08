pragma solidity ^ 0.4 .13;

contract SafeMath {
    function safeMul(uint a, uint b) internal returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal returns(uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns(uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    function assert(bool assertion) internal {
        if (!assertion) {
            revert();
        }
    }
}




contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) owner = newOwner;
    }

    function kill() {
        if (msg.sender == owner) selfdestruct(owner);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert();
            _;
    }
}

contract Pausable is Ownable {
    bool public stopped;

    modifier stopInEmergency {
        if (stopped) {
            revert();
        }
        _;
    }

    modifier onlyInEmergency {
        if (!stopped) {
            revert();
        }
        _;
    }

    // Called by the owner in emergency, triggers stopped state
    function emergencyStop() external onlyOwner {
        stopped = true;
    }

    // Called by the owner to end of emergency, returns to normal state
    function release() external onlyOwner onlyInEmergency {
        stopped = false;
    }
}




// Presale Smart Contract
// This smart contract collects ETH during presale. Tokens are not distributed during
// this time. Only informatoion stored how much tokens should be allocated in the future.
contract Presale is SafeMath, Pausable {

    struct Backer {
        uint weiReceived;   // amount of ETH contributed
        uint SOCXSent;      // amount of tokens to be sent
        bool processed;     // true if tokens transffered.
    }
    
    address public multisigETH; // Multisig contract that will receive the ETH    
    uint public ETHReceived;    // Number of ETH received
    uint public SOCXSentToETH;  // Number of SOCX sent to ETH contributors
    uint public startBlock;     // Presale start block
    uint public endBlock;       // Presale end block

    uint public minContributeETH;// Minimum amount to contribute
    bool public presaleClosed;  // Is presale still on going
    uint public maxCap;         // Maximum number of SOCX to sell

    uint totalTokensSold;       // tokens sold during the campaign
    uint tokenPriceWei;         // price of tokens in Wei


    uint multiplier = 10000000000;              // to provide 10 decimal values
    mapping(address => Backer) public backers;  // backer list accessible through address
    address[] public backersIndex;              // order list of backer to be able to itarate through when distributing the tokens. 


    // @notice to be used when certain account is required to access the function
    // @param a {address}  The address of the authorised individual
    modifier onlyBy(address a) {
        if (msg.sender != a) revert();
        _;
    }

    // @notice to verify if action is not performed out of the campaing time range
    modifier respectTimeFrame() {
        if ((block.number < startBlock) || (block.number > endBlock)) revert();
        _;
    }



    // Events
    event ReceivedETH(address backer, uint amount, uint tokenAmount);



    // Presale  {constructor}
    // @notice fired when contract is crated. Initilizes all constnat variables.
    function Presale() {     
           
        multisigETH = 0x7bf08cb1732e1246c65b51b83ac092f9b4ebb8c6; //TODO: Replace address with correct one
        maxCap = 2000000 * multiplier;  // max amount of tokens to be sold
        SOCXSentToETH = 0;              // tokens sold so far
        minContributeETH = 1 ether;     // minimum contribution acceptable
        startBlock = 0;                 // start block of the campaign, it will be set in start() function
        endBlock = 0;                   // end block of the campaign, it will be set in start() function 
        tokenPriceWei = 720000000000000;// price of token expressed in Wei 
    }

    // @notice to obtain number of contributors so later "front end" can loop through backersIndex and 
    // triggger transfer of tokens
    // @return  {uint} true if transaction was successful
    function numberOfBackers() constant returns(uint) {
        return backersIndex.length;
    }

    function updateMultiSig(address _multisigETH) onlyBy(owner) {
        multisigETH = _multisigETH;
    }


    // {fallback function}
    // @notice It will call internal function which handels allocation of Ether and calculates SOCX tokens.
    function () payable {
        if (block.number > endBlock) revert();
        handleETH(msg.sender);
    }

    // @notice It will be called by owner to start the sale
    // TODO WARNING REMOVE _block parameter and _block variable in function
    function start() onlyBy(owner) {
        startBlock = block.number;        
        endBlock = startBlock + 57600;
        // 10 days in blocks = 57600 (4*60*24*10)
        // enable this for live assuming each bloc takes 15 sec.
    }

    // @notice called to mark contributer when tokens are transfered to them after ICO
    // @param _backer {address} address of beneficiary
    function process(address _backer) onlyBy(owner) returns (bool){

        Backer storage backer = backers[_backer]; 
        backer.processed = true;

        return true;
    }

    // @notice It will be called by fallback function whenever ether is sent to it
    // @param  _backer {address} address of beneficiary
    // @return res {bool} true if transaction was successful
    function handleETH(address _backer) internal stopInEmergency respectTimeFrame returns(bool res) {

        if (msg.value < minContributeETH) revert();                     // stop when required minimum is not sent
        uint SOCXToSend = (msg.value / tokenPriceWei) * multiplier; // calculate number of tokens

        
        if (safeAdd(SOCXSentToETH, SOCXToSend) > maxCap) revert();  // ensure that max cap hasn&#39;t been reached yet

        Backer storage backer = backers[_backer];                   // access backer record
        backer.SOCXSent = safeAdd(backer.SOCXSent, SOCXToSend);     // calculate number of tokens sent by backer
        backer.weiReceived = safeAdd(backer.weiReceived, msg.value);// store amount of Ether received in Wei
        ETHReceived = safeAdd(ETHReceived, msg.value);              // update the total Ether recived
        SOCXSentToETH = safeAdd(SOCXSentToETH, SOCXToSend);         // keep total number of tokens sold
        backersIndex.push(_backer);                                 // maintain iterable storage of contributors

        ReceivedETH(_backer, msg.value, SOCXToSend);                // register event
        return true;
    }



    // @notice This function will finalize the sale.
    // It will only execute if predetermined sale time passed 
    // if successfull it will transfer collected Ether into predetermined multisig wallet or address
    function finalize() onlyBy(owner) {

        if (block.number < endBlock && SOCXSentToETH < maxCap) revert();

        if (!multisigETH.send(this.balance)) revert();
        presaleClosed = true;

    }

    
    // @notice Failsafe drain
    // in case finalize failes, we need guaranteed way to transfer Ether out of this contract. 
    function drain() onlyBy(owner) {
        if (!owner.send(this.balance)) revert();
    }

}