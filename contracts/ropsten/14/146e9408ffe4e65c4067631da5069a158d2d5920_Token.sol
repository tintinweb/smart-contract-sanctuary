pragma solidity 0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";



contract Token is ERC20 {
    
    // MULTI OWNER - START
    mapping(address => bool) public managers; // creo una mapping di managers per risparmio costi in caso su alcune operazioni
    address[] public managersArray; // creato per fare un get con poca spesa
    address public deployer;
    string[] public messagesArray;
    
    
    constructor() ERC20("MyTestLimited", "MTSL", 1000 * (10 ** uint256(18)) ) {
        _mint(msg.sender, 1000 * (10 ** uint256(18)));
        managers[msg.sender] = true;
        managersArray.push(msg.sender);
        deployer = msg.sender;
    }

    function addManagers(address newManagerAddress) public restricted{ // Funzione per aggiungere owners
        require(!managers[newManagerAddress]); 
        
        managers[newManagerAddress] = true;
        managersArray.push(newManagerAddress);
    }
    
    function deleteManager(address managerAddress) public restricted{ // rimuovere un manager da un array
        if(managerAddress == deployer)
        {
            revert();
        }
        
        require(managers[managerAddress], "Not deleted! Manager not present");
        require(managersArray.length>1, "The contract requires at least one manager"); 
        
        
        delete managers[managerAddress]; // lo elimina dalla maps
        
        //remove from array
        for(uint i = 0; i < managersArray.length; i++)
        {
            if(managersArray[i] == managerAddress)
            {
                delete managersArray[i];
                //managersArray.length--;
                return;
            }
        }
    }
    
    function viewManagers() public view returns(address[] memory){
        return managersArray;
    }
    
    modifier restricted() { // permette operazione solo ai managers
        require(managers[msg.sender], "this is not manager");
        _;
    }

    
}