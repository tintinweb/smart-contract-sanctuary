pragma solidity ^0.4.25;

contract Token {
    function transfer(address receiver, uint amount) public;
    function balanceOf(address receiver)public returns(uint);
}

///@title Axioms-Airdrops
///@author  Lucasxhy & Kafcioo

contract Axioms {
    Airdrop [] public airdrops;
    address public owner;

    ///@notice  Set the creator of the smart contract to be its sole owner
    constructor () public {
        owner = msg.sender;
    }


    ///@notice  Modifier to require a minimum amount fo ether for the function to add and airdrop
    modifier minEth {
        require(msg.value >= 200000000000000000); // 0.2ETH Change this to amount of eth needed for gas fee in GWEI!
        _;
    }
    ///@notice  Modifier that only allows the owner to execute a function
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    ///@notice  Creates a structure for airdrops, which stores all the necessary information for users to look up the history effectively and directly from the smart contract.
    struct Airdrop {
        string name;
        uint id;
        uint tokenAmount;
        uint countDown;
        uint timeStamp;
        uint gasFeePaid;
        uint decimals;
        address distributor;
        Token tokenSC;
    }
    ///@notice  Adds a new airdrop to the smart contract and starts the count down until it is distributed
   function addNewAirdrop(
   string _name,
   uint _tokenAmount,
   uint _countDown,
   address  _smartContract,
   uint _decimals
   )
   public
   minEth
   payable
   {
       Token t = Token(_smartContract);
       if(t.balanceOf(this)>=_tokenAmount){
        uint lastIndex = airdrops.length++;
        Airdrop storage airdrop = airdrops[lastIndex];
        airdrop.name=_name;
        airdrop.id =lastIndex;
        airdrop.decimals = _decimals;
        airdrop.tokenAmount = _tokenAmount;
        airdrop.countDown=_countDown;
        airdrop.gasFeePaid= msg.value;
        airdrop.timeStamp=now;
        airdrop.distributor = msg.sender;
        airdrop.tokenSC = Token(_smartContract);
       }else revert(&#39;Air Drop not added, Please make sure you send your ERC20 tokens to the smart contract before adding new airdrop&#39;);
   }

    ///@notice  Distirbutes a differen quantity of tokens to all the specified addresses.
    ///@dev Distribution will only occur when a distribute function is called, and passed the correct parameters, it is not the smart contracts job to produce the addresses or determine the ammounts
    ///@param index  The airdrop to distribute based in the the array in which is saved
    ///@param _addrs The set of addresses in array form, to which the airdrop will be distributed
    ///@param _vals  The set of values to be distributed to each address in array form
    function distributeAirdrop(
        uint index,
        address[] _addrs,
        uint[] _vals
    )
        public
        onlyOwner
    {
        Airdrop memory airdrop = airdrops[index];
        if(airdrop.countDown <=now) {
            for(uint i = 0; i < _addrs.length; ++i) {
                airdrop.tokenSC.transfer(_addrs[i], _vals[i]);
            }
        } else revert("Distribution Failed: Count Down not gone yet");
    }


  // Refound tokens back to the to airdrop creator
    function refoundTokens(
        uint index

    )
        public
        onlyOwner
    {

        Airdrop memory airdrop = airdrops[index];
        airdrop.tokenSC.transfer(airdrop.distributor,airdrop.tokenAmount);
    }

    function transferGasFee(uint index) public onlyOwner {
           Airdrop memory airdrop = airdrops[index];
           owner.transfer(airdrop.gasFeePaid);
       }
}