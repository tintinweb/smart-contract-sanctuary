//SourceUnit: DApp.sol

// SPDX-License-Identifier: SimPL-2.0
pragma solidity 0.6.12;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IHOOH is IERC20 {
    function updateInviter(address addr, address inviter) external returns (bool);

    function getMemberAmount(address account) external view returns (uint256);
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract DApp is Ownable {

    IHOOH public hooh;

    mapping(address => bool) private executors;

    //TU9pmKkj8n8dZTAisu1huPkQVGD92ahtFS
    address private SUPER_ADDRESS = address(0x00c77446ff75b01da6124c7dafc0397c3f1deeadd5);

    constructor(address _hoohTokenAddress, address _superAddress) public {
        //操作资金池的地址
        executors[address(0x000f5f5b4dee29266e70ea27604bf7c2f9c35a641b)] = true;
        hooh = IHOOH(_hoohTokenAddress);
        SUPER_ADDRESS = _superAddress;
    }

    function updateBaseAddress(address addr) public onlyOwner returns (bool){
        require(addr != address(0x0), "address error");
        SUPER_ADDRESS = addr;
        return true;
    }

    function updateExecutor(address _address, bool isExe) public onlyOwner returns (bool){
        executors[_address] = isExe;
        return true;
    }

    modifier onlyExecutor() {
        require(executors[msg.sender]);
        _;
    }

    function transferIERC20(address _contract, address to, uint256 amount) public onlyExecutor returns (bool){
        IERC20(_contract).transfer(to, amount);
        return true;
    }

    function transferTRX(address payable to, uint256 amount) public onlyExecutor returns (bool){
        to.transfer(amount);
        return true;
    }

    function signUp(address inviter) public payable returns (bool){
        if (inviter == address(0x0)) {
            hooh.updateInviter(msg.sender, SUPER_ADDRESS);
        } else {
            hooh.updateInviter(msg.sender, inviter);
        }
        return true;
    }

    function getMemberCount(address account) public view returns (uint256){
        return hooh.getMemberAmount(account);
    }


    function updateHooh(address hoohAddr) public onlyOwner returns (bool){
        hooh = IHOOH(hoohAddr);
        return true;
    }
}