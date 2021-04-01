/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

pragma solidity =0.5.12;

contract LibNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  usr,
        bytes32  indexed  arg1,
        bytes32  indexed  arg2,
        bytes             data
    ) anonymous;

    modifier note {
        _;
        assembly {
        // log an 'anonymous' event with a constant 6 words of calldata
        // and four indexed topics: selector, caller, arg1 and arg2
            let mark := msize                         // end of memory ensures zero
            mstore(0x40, add(mark, 288))              // update free memory pointer
            mstore(mark, 0x20)                        // bytes type data offset
            mstore(add(mark, 0x20), 224)              // bytes size (padded)
            calldatacopy(add(mark, 0x40), 0, 224)     // bytes payload
            log4(mark, 288,                           // calldata
            shl(224, shr(224, calldataload(0))), // msg.sig
            caller,                              // msg.sender
            calldataload(4),                     // arg1
            calldataload(36)                     // arg2
            )
        }
    }
}

interface IERC20 {
    function transfer(address,uint) external returns (bool);
}

contract wOST is LibNote {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) external note auth { wards[guy] = 1; }
    function deny(address guy) external note auth { wards[guy] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "WOST/not-authorized");
        _;
    }

    // --- ERC20 Data ---
    string  public constant name     = "wOST";
    string  public constant symbol   = "WOST";
    string  public constant version  = "1.0.0";
    uint8   public constant decimals = 18;
    uint256 public totalSupply;
    uint256 public live;

    address source;

    mapping (address => uint)                      public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);

    // --- Math ---
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }

    constructor(address _source) public {
        wards[msg.sender] = 1;
        live = 1;
        source = _source;
    }

    // --- Token ---
    function transfer(address dst, uint wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }
    function transferFrom(address src, address dst, uint wad)
    public returns (bool)
    {
        require(live == 1, "WOST/not-live");
        require(balanceOf[src] >= wad, "WOST/insufficient-balance");
        if (src != msg.sender) {
            require(allowance[src][msg.sender] >= wad, "WOST/insufficient-allowance");
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
        }
        balanceOf[src] = sub(balanceOf[src], wad);
        balanceOf[dst] = add(balanceOf[dst], wad);
        emit Transfer(src, dst, wad);
        return true;
    }
    function mint(address usr, uint wad) external auth {
        balanceOf[usr] = add(balanceOf[usr], wad);
        totalSupply    = add(totalSupply, wad);
        emit Transfer(address(0), usr, wad);
    }
    function burn(address usr, uint wad) external auth {
        require(balanceOf[usr] >= wad, "WOST/insufficient-balance");
        balanceOf[usr] = sub(balanceOf[usr], wad);
        totalSupply    = sub(totalSupply, wad);
        emit Transfer(usr, address(0), wad);
    }
    function approve(address usr, uint wad) external returns (bool) {
        allowance[msg.sender][usr] = wad;
        emit Approval(msg.sender, usr, wad);
        return true;
    }

    function exit(uint wad) external returns (bool) {
        require(balanceOf[msg.sender] >= wad, "WOST/insufficient-balance");
        balanceOf[msg.sender] = sub(balanceOf[msg.sender] , wad);
        totalSupply = sub(totalSupply, wad);
        emit Transfer(msg.sender, address(0), wad);
        return IERC20(source).transfer(msg.sender, wad);
    }

    /*
     * Emergency shutdown
     */
    function cage() external note auth {
        live = 0;
    }

    function restart() external note auth {
        live = 1;
    }
}