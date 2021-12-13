/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

pragma solidity 0.6.2;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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


contract mother{
    event deployed(address);

    //three following functions are three ways to deploy new child
    function create_child() external returns(child){
        emit deployed(address(new child()));
    }

    function create_child_new(string calldata salt) external returns(child){
        bytes memory tempEmptyStringTest = bytes(salt);
        bytes32 sb32;
        assembly {
            sb32 := mload(add(tempEmptyStringTest, 32))
        }
            emit deployed(address(new child{salt: sb32}()));
    }

    function create_child_assembly(bytes memory bytecode, uint _salt) public {
        address addr;
        assembly {
            addr := create2(
                0,
                add(bytecode, 0x20),
                mload(bytecode),
                _salt
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        emit deployed(addr);
    }

    function getBytecode() public pure returns (bytes memory) {
        bytes memory bytecode = type(child).creationCode;

        return abi.encodePacked(bytecode, abi.encode());
    }

    function getAddress(bytes memory bytecode, uint _salt)
        public
        view
        returns (address){
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode))
        );

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint(hash)));
    }

    function withdraw(
        address child,
        address token,
        uint amount) external {
            ichild(child).withdraw_token(token, amount);
    }

    receive() external payable{}
}

contract child{
    address payable private constant owner = 0xA481BF9D6Be38d8F992dFA41793FaFE2c4b7f510;
    fallback() external payable{
        if(msg.data.length > 0){
            bytes memory data = msg.data;
            address token;
            uint amount;
            assembly {
                token := mload(add(data, add(0x20, 4)))
                amount := mload(add(data, add(0x20, 36)))
            }
            if(token == address(0))
                owner.transfer(amount);
            else
                IERC20(token).transfer(owner, amount); 
        }    
    }
}

interface ichild{
    function withdraw_token(address token, uint amount) external;
}