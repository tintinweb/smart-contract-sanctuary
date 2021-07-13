/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;
contract FalconToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply= 0;

    address public owner;
    modifier ownerOnly {
        require(msg.sender == owner, "This function is restricted to owner");
        _;
    }
    modifier issuerOnly {
        require(isIssuer[msg.sender], "You do not have issuer rights");
        _;
    }

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public isIssuer;
    mapping (address => bool) public isBlackListed;
    

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event IssuerRights(address indexed issuer, bool value);
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);
    event AddedBlackList(address _user, bool isBlackListed);
    event RemovedBlackList(address _user, bool isRemovedFromBlackList);
    event DestroyedBlackFunds(address _blackListedUser, uint256 dirtyFunds);

    // function getOwner() public view returns (address) {
    //     return owner;
    // }

    function mint(address _to, uint256 _amount) public issuerOnly returns (bool success) {
        totalSupply += _amount;
        balanceOf[_to] += _amount;
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function burn(uint256 _amount) public issuerOnly returns (bool success) {
        totalSupply -= _amount;
        balanceOf[msg.sender] -= _amount;
        emit Transfer(msg.sender, address(0), _amount);
        return true;
    }

    function burnFrom(address _from, uint256 _amount) public issuerOnly returns (bool success) {
        allowance[_from][msg.sender] -= _amount;
        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
        emit Transfer(_from, address(0), _amount);
        return true;
    }

    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(!isBlackListed[_to], "recipient is blacklisted");
        require(!isBlackListed[msg.sender], "you are blacklisted");
        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom( address _from, address _to, uint256 _amount) public returns (bool success) {
        require(!isBlackListed[_to], "recipient is blacklisted");
        require(!isBlackListed[_from], "holder is blacklisted");
        require(!isBlackListed[msg.sender], "you are blacklisted");
        allowance[_from][msg.sender] -= _amount;
        balanceOf[_from] -= _amount;
        balanceOf[_to] += _amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    function addBlackList (address _user) public ownerOnly {
        isBlackListed[_user] = true;
        emit AddedBlackList(_user, isBlackListed[_user]);
    }

    function removeBlackList (address _user) public ownerOnly {
        isBlackListed[_user] = false;
        emit RemovedBlackList(_user, !isBlackListed[_user]);
    }

    function destroyBlackFunds (address _blackListedUser) public ownerOnly {
        require(isBlackListed[_blackListedUser]);
        uint256 dirtyFunds = balanceOf[_blackListedUser];
        balanceOf[_blackListedUser] = 0;
        totalSupply -= dirtyFunds;
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }

    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != address(0), "Invalid address: should not be 0x0");
        emit TransferOwnership(owner, _newOwner);
        owner = _newOwner;
    }

    function setIssuerRights(address _issuer, bool _value) public ownerOnly {
        isIssuer[_issuer] = _value;
        emit IssuerRights(_issuer, _value);
    }
    //0x473be604
    function constructor1() public {
        name = "Falcon";
        symbol = "FNT";
        decimals = 6;
        owner = msg.sender;
        
        emit TransferOwnership(address(0), msg.sender);
    }
    
}

contract Proxy {
    // Code position in storage is keccak256("WEARETHEFALCON") = "0x2188b6d4e73d37025fd2b6d16decd9bf9d2a93a5df9daed92a727a96b821546e"
    constructor(bytes memory constructData, address contractLogic) {
        // save the code address
        assembly { // solium-disable-line
            sstore(0x2188b6d4e73d37025fd2b6d16decd9bf9d2a93a5df9daed92a727a96b821546e, contractLogic)
        }
        (bool success, bytes memory result ) = contractLogic.delegatecall(constructData); // solium-disable-line
        require(success, "Construction failed");
    }

    fallback() external payable {
        assembly { // solium-disable-line
            let contractLogic := sload(0x2188b6d4e73d37025fd2b6d16decd9bf9d2a93a5df9daed92a727a96b821546e)
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(sub(gas(), 10000), contractLogic, 0x0, calldatasize(), 0, 0)
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }
}

contract Proxiable {
    // Code position in storage is keccak256("WEARETHEFALCON") = "0x2188b6d4e73d37025fd2b6d16decd9bf9d2a93a5df9daed92a727a96b821546e"

    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(0x2188b6d4e73d37025fd2b6d16decd9bf9d2a93a5df9daed92a727a96b821546e) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly { // solium-disable-line
            sstore(0x2188b6d4e73d37025fd2b6d16decd9bf9d2a93a5df9daed92a727a96b821546e, newAddress)
        }
    }

    function proxiableUUID() public pure returns (bytes32) {
        return 0x2188b6d4e73d37025fd2b6d16decd9bf9d2a93a5df9daed92a727a96b821546e;
    }
} 

contract FinalFalconToken is FalconToken, Proxiable {
    // new wcode is taht case is 0x473be604, just dont change name and arguments of function constructor1() from FalconToken  
    function updateCode(address newCode) ownerOnly public {
        updateCodeAddress(newCode);
    }
}