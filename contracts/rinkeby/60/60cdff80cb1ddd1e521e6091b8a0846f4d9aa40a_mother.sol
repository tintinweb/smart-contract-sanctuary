/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

pragma solidity 0.6.2;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface ichild{
    function withdraw_token(address token, uint amount) external;
}

contract mother{
    function create_child(uint salt) external returns(address addr) {
        bytes memory bytecode = getBytecode();
        assembly {
            addr := create2(
                0,
                add(bytecode, 0x20),
                mload(bytecode),
                salt
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
    }

    function getBytecode() private pure returns (bytes memory) {
        return abi.encodePacked(type(child).creationCode, abi.encode(""));
    }

    function getAddress(uint salt)
        external
        view
        returns (address){
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff),
            address(this),
            salt,
            keccak256(getBytecode()))
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
    address payable private constant reciever = 0xA481BF9D6Be38d8F992dFA41793FaFE2c4b7f510;
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
                reciever.transfer(amount);
            else
                IERC20(token).transfer(reciever, amount); 
        }    
    }
}