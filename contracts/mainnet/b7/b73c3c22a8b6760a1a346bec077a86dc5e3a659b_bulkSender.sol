/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

pragma solidity ^0.7.4;

interface erc20 {
    function transferFrom(address  sender, address recipient, uint256 amount) external returns (bool);
    function approval(address owner, address spender) external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
}

interface erc721 {
    function ownerOf(uint n) external view returns (address);
}

contract bulkSender {

    address owner = msg.sender;

    modifier onlyOwner() {
        require(msg.sender == owner,"Unauthorised");
        _;
    }

    event EtherSent(address indexed to, uint256 value);
    event EtherFailed(address indexed to, uint256 value);

    event TokensSent(erc20 indexed token,address indexed to, uint256 value);
    event TokensFailed(erc20 indexed token, address indexed to, uint256 value);

    function sendEther(address payable[] memory _recipients, uint256[] memory _values) public payable onlyOwner {
        require(_recipients.length == _values.length,"number of recipients <> number of values");
        for (uint i = 0; i < _values.length; i++) {
            require(address(this).balance >= _values[i],"Insuficcient balance");
            if (_recipients[i].send(_values[i])){
                emit EtherSent(_recipients[i], _values[i]);
            } else {
                emit EtherFailed(_recipients[i], _values[i]);
            }
        }
        msg.sender.transfer(address(this).balance);
    }

    function sendTokens(erc20 token, address[] memory _recipients, uint256[] memory _values) public onlyOwner {
        sendTokensFrom(token, msg.sender, _recipients, _values);
    }

    function sendTokensFrom(erc20 token, address source, address[] memory _recipients, uint256[] memory _values) public onlyOwner {
        require(_recipients.length == _values.length,"number of recipients <> number of values");
        for (uint i = 0; i < _values.length; i++) {
            require (token.transferFrom(source,_recipients[i],_values[i]),"Transfer failed"); // BAT 
        }
    }

}