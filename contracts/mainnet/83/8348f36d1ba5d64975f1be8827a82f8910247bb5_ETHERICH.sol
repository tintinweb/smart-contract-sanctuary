pragma solidity ^0.4.20;

contract ETHERICH {

    event Bought(string name, string quote, uint amount);
    event Overwrite(string name, string quote);

    address private owner;

    uint256 private _increase = 1000000000000000;

    uint256 private _highestBid = 1000000000000000;
    string private _highestNickName = "ETHERICH";
    string private _highestQuote = "Your quote here!";

    constructor() public {
        owner = msg.sender;
    }

    function buy(string _nickname, string _quote) public payable {
        require(msg.value > 0);
        require(msg.value >= (_highestBid + _increase));

        uint nickname_len = bytes(_nickname).length;
        uint quote_len = bytes(_quote).length ;

        require(nickname_len > 0 && nickname_len <= 28);
        require(quote_len > 0 && quote_len <= 60);

        _highestNickName = _nickname;
        _highestQuote = _quote;
        _highestBid = msg.value;

        emit Bought(_highestNickName,_highestQuote,_highestBid);
    }


    function getRichest() public view returns(string,string, uint) {
        return (_highestNickName,_highestQuote, _highestBid);
    }

    function getIncrease() public view returns(uint) {
        return _increase;
    }

    function overwrite(string _nickname, string _quote) public{
        require(msg.sender == owner);
        uint nickname_len = bytes(_nickname).length;
        uint quote_len = bytes(_quote).length ;

        require(nickname_len > 0 && nickname_len <= 28);
        require(quote_len > 0 && quote_len <= 60);

        _highestNickName = _nickname;
        _highestQuote = _quote;
        emit Overwrite(_highestNickName,_highestQuote);
    }

    function updateIncrease(uint256 increase) public {
        require(msg.sender == owner);
        _increase = increase;
    }

    function withDraw() public{
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }
}