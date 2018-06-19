// IMAERO.IO

// My name is Alexander Kosachev, I AM AERO Founder. 
// I would like to present you I AM AERO project - real company from real economy sector. 
// We have more than 15-years history of creation of aviation equipment and helicopters. 
// Company with great potential for development in real time.

// By this link you&#39;ll find more information about I AM AERO 
// https://www.youtube.com/watch?v=7NJS4UFVMDQ

// For more information, please visit our website: www.iamaero.io
// Token sale is in process at the moment. Take a chance!

// Telegram: @Kosachev_as
// Best regards,
// Alexander Kosachev, 
// Founder&CEO I AM AERO
// Facebook www.facebook.com/kosachev.as
// Telegram: @Kosachev_as


contract ERC20 {
    function balanceOf(address who) public view returns(uint256);
    function transfer(address to, uint256 value) public returns(bool);
}

contract TokenDrop {
    ERC20 token;

    function TokenDrop() {
        token = ERC20(0xec662B61C129fcF9fc6DD6F1A672021A539CE45d);
    }

    function multiTransfer(uint256 _value, address[] _to) public returns(bool) {
        for(uint i = 0; i < _to.length; i++) {
            token.transfer(_to[i], _value);
        }

        return true;
    }

    function balanceOf(address who) public view returns(uint256) {
        return token.balanceOf(who);
    }
}