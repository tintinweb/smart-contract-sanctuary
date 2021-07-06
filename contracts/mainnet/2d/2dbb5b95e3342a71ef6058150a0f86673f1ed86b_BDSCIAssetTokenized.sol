/**
 *Submitted for verification at Etherscan.io on 2021-07-06
*/

pragma solidity ^0.5.12;

contract BDSCITransferableTrustFundAccount {
    address owner;

    constructor() public {
        owner = msg.sender;
    }

    function withdrawAll() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }

    function withdrawAmount(uint256 amount) public {
        require(owner == msg.sender);
        require(address(this).balance >= amount);
        msg.sender.transfer(amount);
    }

    function() external payable {}

    function transferAccount(address newAccount) public {
    require(owner == msg.sender);
    require(newAccount != address(0));
    owner = newAccount;
    }

    function terminateAccount() public {
    require(owner == msg.sender);
    selfdestruct(msg.sender);
    }
}

contract BDSCIAssetTokenized{
uint public supply;
uint public pricePerEth;
mapping( address => uint ) public balance;

constructor() public {
    supply = 1000000000000;                    // There are a total of 1000 tokens for this asset
    pricePerEth = 100000000000000000; // One token costs 0.1 ether
  }

  function check() public view returns(uint) {
    return balance[msg.sender];
  }

  function () external payable {
    balance[msg.sender] += msg.value/pricePerEth; // adds asset tokens to how much ether is sent by the investor
    supply -= msg.value/pricePerEth;              //subtracts the remaining asset tokens from the total supply
  }
}

contract CoreInterface {

    /* Module manipulation events */

    event ModuleAdded(string name, address indexed module);

    event ModuleRemoved(string name, address indexed module);

    event ModuleReplaced(string name, address indexed from, address indexed to);


    /* Functions */

    function set(string memory  _name, address _module, bool _constant) public;

    function setMetadata(string memory _name, string  memory _description) public;

    function remove(string memory _name) public;
    
    function contains(address _module)  public view returns (bool);

    function size() public view returns (uint);

    function isConstant(string memory _name) public view returns (bool);

    function get(string memory _name)  public view returns (address);

    function getName(address _module)  public view returns (string memory);

    function first() public view returns (address);

    function next(address _current)  public view returns (address);
}

library ISQRT {

    /**
     * @notice Calculate Square Root
     * @param n Operand of sqrt() function
     * @return greatest integer less than or equal to the square root of n
     */
    function sqrt(uint256 n) internal pure returns(uint256){
        return sqrtBabylonian(n);
    }

    /**
     * Based on Martin Guy implementation
     * http://freaknet.org/martin/tape/gos/misc/personal/msc/sqrt/sqrt.c
     */
    function isqrtBitByBit(uint256 x) internal pure returns (uint256){
        uint256 op = x;
        uint256 res = 0;
        /* "one" starts at the highest power of four <= than the argument. */
        uint256 one = 1 << 254; /* second-to-top bit set */
        while (one > op) {
            one = one >> 2;
        }
        while (one != 0) {
            if (op >= res + one) {
                op = op - (res + one);
                res = res + (one << 1);
            }
            res = res >> 1;
            one = one >> 2;
        }
        return res;
    }

    /**
     * Babylonian method implemented in dapp-bin library
     * https://github.com/ethereum/dapp-bin/pull/50
     */
    function sqrtBabylonian(uint256 x) internal pure returns (uint256) {
        // x == MAX_UINT256 makes this method fail, so in this case return value calculated separately
        if (x == 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) return 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2; //No overflow possible here, because greatest possible z = MAX_UINT256/2
        }
        return y;
    }
}