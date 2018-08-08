// Lottery Source code

pragma solidity ^0.4.21;


/// @title A base contract to control ownership
/// @author cuilichen
contract OwnerBase {

    // The addresses of the accounts that can execute actions within each roles.
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;
    
    /// constructor
    function OwnerBase() public {
       ceoAddress = msg.sender;
       cfoAddress = msg.sender;
       cooAddress = msg.sender;
    }

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    /// @dev Access modifier for CFO-only functionality
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }
    
    /// @dev Access modifier for COO-only functionality
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }


    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCFO The address of the new COO
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }
    
    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCOO The address of the new COO
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Called by any "C-level" role to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause() external onlyCOO whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when CFO or COO accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyCOO whenPaused {
        // can&#39;t unpause if contract was upgraded
        paused = false;
    }
    
    
    /// @dev check wether target address is a contract or not
    function isNormalUser(address addr) internal view returns (bool) {
        if (addr == address(0)) {
            return false;
        }
        uint size = 0;
        assembly { 
            size := extcodesize(addr) 
        } 
        return size == 0;
    }
}


contract Lottery is OwnerBase {

    event Winner( address indexed account,uint indexed id, uint indexed sn );
    
    uint public price = 1 finney;
    
    uint public reward = 10 finney;
    
    uint public sn = 1;
    
    uint private seed = 0;
    
    
    /// @dev constructor of contract, create a seed
    function Lottery() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
        cfoAddress = msg.sender;
        seed = now;
    }
    
    /// @dev set seed by coo
    function setSeed( uint val) public onlyCOO {
        seed = val;
    }
    
    
    function() public payable {
        // get ether, maybe from coo.
    }
        
    
    
    /// @dev buy lottery
    function buy(uint id) payable public {
        require(isNormalUser(msg.sender));
        require(msg.value >= price);
        uint back = msg.value - price;  
        
        sn++;
        uint sum = seed + sn + now + uint(msg.sender);
        uint ran = uint16(keccak256(sum));
        if (ran * 10000 < 880 * 0xffff) { // win the reward 
            back = reward + back;
            emit Winner(msg.sender, id, sn);
        }else{
            emit Winner(msg.sender, id, 0);
        }
        
        if (back > 1 finney) {
            msg.sender.transfer(back);
        }
    }
    
    

    // @dev Allows the cfo to capture the balance.
    function cfoWithdraw( uint remain) external onlyCFO {
        address myself = address(this);
        require(myself.balance > remain);
        cfoAddress.transfer(myself.balance - remain);
    }
    
    
    
    
}