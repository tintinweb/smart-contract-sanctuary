// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./OpenZeppelin/Ownable.sol";
import "./OpenZeppelin/SafeMath.sol";
import "./OpenZeppelin/Interfaces/IERC20.sol";

contract TokenSaleVault is Ownable {
    using SafeMath for uint256;

    IERC20 public token;

    uint256 public totalTokenIssue;
    uint public contractAddedTotal;
    
    struct Vault {
        uint256 qty;
        string saleType;
        uint256 dateEncoded;
        uint256 dateIssue;
    }

    event AddedTokenSaleContract(
        address contract_addresss,
        uint256 qty,
        string saleType
    );

    event UpdateTokenSaleContract(
        address contract_addresss,
        uint256 qty,
        string saleType
    );

    event IssueToken(
        address contract_addresss,
        uint256 qty
    );

    event TransferTokenSuppy(
        address contract_address,
        uint256 qty,
        string contract_description
    );

    event DeleteTokenSaleContract(address contract_addresss, string saleType);

    mapping(address => Vault) public tokenVault;
    mapping(uint => address) public contractAddedList;

    function setToken(IERC20 _token) public onlyOwner {
        token = _token;
    }

    function tokenSupply() public view returns (uint256) {
        return tokenBalance() + totalTokenIssue;
    }

    function tokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function tokenIssueBalance() public view returns (uint) {
        return tokenSupply().sub(totalTokenIssue);
    }

    function addNewTokenSale(
        address _address,
        uint256 _qty,
        string memory _saleType
    ) public validate(_address, _qty) onlyOwner {

        require(_address != address(0), "Zero address not allowed");
        require(_qty > 0, "Token Qty must greater than zero" );
        require(isContract(_address), "Address is not a contract");
        
        Vault storage vault   = tokenVault[_address];
        require(vault.qty == 0,"Duplicate contract");

        vault.qty             = _qty;
        vault.saleType        = _saleType;
        vault.dateEncoded     = block.timestamp;
        vault.dateIssue       = 0;
        
        
        contractAddedTotal++;
        contractAddedList[contractAddedTotal] = _address;

        emit AddedTokenSaleContract(_address, _qty, _saleType);
    }

    function issueToken(address _address) public onlyOwner {
        require(_address != address(0), "Zero address not allowed");
        require(isContract(_address), "Address not a contract.");

        uint dateIssue = block.timestamp;
        
        Vault storage vault   = tokenVault[_address];
        require(vault.dateIssue == 0, "Token is already issue");
       
        vault.dateIssue       = dateIssue;
        
        uint qty = vault.qty;
       
        totalTokenIssue += qty;
        
        token.transfer(_address, qty);
        
        emit IssueToken(_address, qty);
    }


    function deleteTokenSale(uint index) public onlyOwner {
        
        address _contract = contractAddedList[index];
        
        Vault storage vault   = tokenVault[_contract];
        require(vault.qty > 0, "Contract not exists.");
        require(vault.dateIssue == 0, "Cannot delete contract already issue.");

       
        delete tokenVault[_contract];
        delete contractAddedList[index];
        contractAddedTotal--;
       
        emit DeleteTokenSaleContract(_contract, vault.saleType);
    }
    

    modifier validate(address _address, uint _qty) {
        require(_address != address(0), "Zero address not allowed");
        require(_qty > 0, "Token Qty must greater than zero" );
        _;
    }
    
    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }



      /** Transfer token left into another contract like reward, airdrop, etc. */
      function transferTokenSupply(
        address _address,
        uint256 _transferAmount,
        string memory contract_description
    ) public onlyOwner {
        require(address(0) != _address, "Address zero detected.");
        require(_transferAmount > 0, "Amount should be greater than zero");
        require(tokenIssueBalance() >= _transferAmount, "Amount exceed to token balance");
        
        token.transfer(_address, _transferAmount);

        emit TransferTokenSuppy(
            _address,
            _transferAmount,
            contract_description
        );
    }






}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Context.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    
    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
   
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
    

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    
    
    function transfer(address recipient, uint256 amount) external returns (bool);
    
    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
    
    
    
   
    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


abstract contract Context {
    
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

}