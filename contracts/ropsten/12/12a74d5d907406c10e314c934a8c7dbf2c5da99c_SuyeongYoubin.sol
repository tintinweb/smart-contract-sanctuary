// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import './ERC20.sol';
import './AccessControl.sol';


contract SuyeongYoubin is ERC20, AccessControl{

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
   
    uint INITIAL_SUPPLY = 365 * 24 * 60 * 60 ;
   
    constructor() ERC20("SuyeongYoubin", "SYBT") {
        _mint(msg.sender, INITIAL_SUPPLY * 10 **(uint(decimals())));
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
    }
   
    function name() public view virtual override returns (string memory) {
        return "Su-yeong You-bin";
    }

    function symbol() public view virtual override returns (string memory) {
        return "SYBT";
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
  
    function burn(address from, uint256 amount) public onlyRole(BURNER_ROLE) {
        _burn(from, amount);
    }
        function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
        function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
        function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

       function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }


    
}