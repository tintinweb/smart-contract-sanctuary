// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IERC20Minter {
    function mint(address account, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./IERC20Minter.sol";

contract SuperSpreader {

    event sendEther(address indexed receiver, uint256 amount);
    event deposit   (address indexed sender, uint256 amount);
    event changeSpreaderAmount(uint256 amount);

    mapping(address => bool) private _transferDone;
    IERC20Minter[] public erc20;
    address payable public owner;
    uint256 public weiAmount;

    constructor(address payable _owner, uint256 _weiAmount, IERC20Minter[] memory _erc20) payable {
        require(_owner != address(0), "owner cant be null");
        owner = _owner;
        weiAmount = _weiAmount;
        _transferDone[address(0)] = true;

        for(uint256 i = 0; i < _erc20.length ; i++) {
            erc20.push(_erc20[i]);
        }
    }

    function getEther(address payable receiver) external {
        require(_transferDone[receiver] == false, "no double end");
        if(address(this).balance >= weiAmount) {
            _transferDone[receiver] = true;
            receiver.transfer(weiAmount);
            for(uint256 i = 0; i < erc20.length ; i++) {
                mint(erc20[i], receiver);
            }
            emit sendEther(receiver, weiAmount);
        } else {
            revert("Faucet without ether");
        }
    }


    function mint(IERC20Minter token, address receiver) public {
        require(token.mint(receiver, 1000 ether), "something went wrong");
    }

    function addErc20(IERC20Minter token) external {
        require(msg.sender == owner, "not owner");
        require(address(token) != address(0), "zero address");
        erc20.push(token);
    }

    function removeErc20(IERC20Minter token) external {
        require(msg.sender == owner, "not owner");
        _removeErc20(_indexOf(address(token)));
    }

    function changeSpreadingAmount(uint256 newWeiAmount) external {
        require(msg.sender == owner, "not owner");
        weiAmount = newWeiAmount;
    }

    function withdraw() external {
        require(msg.sender == owner, "not owner");
        uint256 balance = address(this).balance;
        owner.transfer(balance);
        emit sendEther(owner, balance);
    }

    function _indexOf(address token) view internal returns(uint256 index) {
        for(uint256 i = 0; i < erc20.length; i++) {
            if(address(erc20[i]) == address(token)) {
                return i;
            }
        }
    }

    function _removeErc20(uint256 index) internal {
        for (uint i = index; i < erc20.length-1; i++){
            erc20[i] = erc20[i+1];
        }
        erc20.pop();
    }


    fallback() external payable {
        revert("send some ether");
    }

    receive() external payable {
        emit deposit(msg.sender, msg.value);
    }
}