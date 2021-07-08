/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

pragma solidity ^0.4.18;
contract CryptoCatsMarket {

    /* You can use this hash to verify the image file containing all cats */
    string public imageHash = "e055fe5eb1d95ea4e42b24d1038db13c24667c494ce721375bdd827d34c59059";

    /* Struct object for storing cat details */
    struct Cat {
        uint256 idNum;         // cat index number
        string name;           // cat name
        bool owned;            // status of cat ownership
        address owner;         // address if cat owner
    }

    /* Variables to store contract owner and contract token standard details */
    address owner;
    string public standard = 'CryptoCats';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;

    bool public allCatsAssigned = false;        // boolean flag to indicate if all available cats are claimed
    uint256 public catsRemainingToAssign = 0;   // variable to track cats remaining to be assigned/claimed

    /* Create array to store cat index to owner address */
    mapping (uint256 => address) public catIndexToAddress;

    /* Create an array with all balances */
    mapping (address => uint256) public balanceOf;

    /* Create array to store cat details like names */
    mapping (uint256 => Cat) public catDetails;

    /* Define event types used to publish to EVM log when cat assignment/claim and cat transfer occurs */
    event Assign(address indexed to, uint256 catIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function CryptoCatsMarket() payable {
        owner = msg.sender;                          // Set contract creation sender as owner
        _totalSupply = 12;                           // Set total supply
        catsRemainingToAssign = _totalSupply;        // Initialise cats remaining to total supply amount
        name = "CRYPTOCATS";                         // Set the name for display purposes
        symbol = "CCAT";                               // Set the symbol for display purposes
        decimals = 0;                                // Amount of decimals for display purposes
        initialiseCats();                            // initialise cat details
    }

    /* Admin function to set all cats assigned flag to true (callable by owner only) */
    function allInitialOwnersAssigned() {
        require(msg.sender == owner);
        allCatsAssigned = true;
    }

    /* Transfer cat by owner to another wallet address
       Different usage in Cryptocats than in normal token transfers 
       This will transfer an owner's cat to another wallet's address
       Cat is identified by cat index passed in as _value */
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (_value < _totalSupply &&                    // ensure cat index is valid
            catIndexToAddress[_value] == msg.sender &&  // ensure sender is owner of cat
            balanceOf[msg.sender] > 0) {                // ensure sender balance of cat exists
            balanceOf[msg.sender]--;                    // update (reduce) cat balance  from owner
            catIndexToAddress[_value] = _to;            // set new owner of cat in cat index
            catDetails[_value].owner = _to;             // set new owner of cat in cat details
            balanceOf[_to]++;                           // update (include) cat balance for recepient
            Transfer(msg.sender, _to, _value);          // trigger event with transfer details to EVM
            success = true;                             // set success as true after transfer completed
        } else {
            success = false;                            // set success as false if conditions not met
        }
        return success;                                 // return success status
    }

    /* Admin function to set all cats details during contract initialisation */
    function initialiseCats() private {
        require(msg.sender == owner);                   // require function caller to be contract owner
        catDetails[0] = Cat(0,"Cat 0", false, 0x0);
        catDetails[1] = Cat(1,"Cat 1", false, 0x0);
        catDetails[2] = Cat(2,"Cat 2", false, 0x0);
        catDetails[3] = Cat(3,"Cat 3", false, 0x0);
        catDetails[4] = Cat(4,"Cat 4", false, 0x0);
        catDetails[5] = Cat(5,"Cat 5", false, 0x0);
        catDetails[6] = Cat(6,"Cat 6", false, 0x0);
        catDetails[7] = Cat(7,"Cat 7", false, 0x0);
        catDetails[8] = Cat(8,"Cat 8", false, 0x0);
        catDetails[9] = Cat(9,"Cat 9", false, 0x0);
        catDetails[10] = Cat(10,"Cat 10", false, 0x0);
        catDetails[11] = Cat(11,"Cat 11", false, 0x0);        
    }

    /* Returns count of how many cats are owned by an owner */
    function balanceOf(address _owner) constant returns (uint256 balance) {
        require(balanceOf[_owner] != 0);    // requires that cat owner balance is not 0
        return balanceOf[_owner];           // return number of cats owned from array of balances by owner address
    }

    /* Return total supply of cats existing */
    function totalSupply() constant returns (uint256 totalSupply) {
        return _totalSupply;
    }

    /* Claim cat at specified index if it is unassigned */
    function claimCat(uint catIndex) {
        require(!allCatsAssigned);                      // require all cats have not been assigned/claimed
        require(catsRemainingToAssign != 0);            // require cats remaining to be assigned count is not 0
        require(catIndexToAddress[catIndex] == 0x0);    // require owner address for requested cat index is empty
        require(catIndex < _totalSupply);               // require cat index requested does not exceed total supply
        catIndexToAddress[catIndex] = msg.sender;       // Assign sender's address as owner of cat
        balanceOf[msg.sender]++;                        // Increase sender's balance holder 
        catsRemainingToAssign--;                        // Decrease cats remaining count
        catDetails[catIndex].owned = true;              // set owned flag in cat details to true for this cat index
        catDetails[catIndex].owner = msg.sender;        // store owner address in cat details for this cat index
        Assign(msg.sender, catIndex);                   // Triggers address assignment event to EVM's
                                                        // log to allow javascript callbacks
    }

    /* Get address of owner based on cat index */
    function getCatOwner(uint256 catIndex) public returns (address) {
        require(catIndexToAddress[catIndex] != 0x0);
        return catIndexToAddress[catIndex];             // Return address at array position of cat index
    }

    /* Get address of contract owner who performed contract creation and initialisation */
    function getContractOwner() public returns (address) {
        return owner;                                   // Return address of contract owner
    }

    /* Get cat details consisting of index, name, owned status and owner address for a particular cat index */
    function getCatDetail(uint256 catIndex) public returns (uint256, string, bool, address) {
        Cat cat = catDetails[catIndex];                         // get cat struct object from cat details array
        return (cat.idNum, cat.name, cat.owned, cat.owner);     // return cat detail values
    }
}