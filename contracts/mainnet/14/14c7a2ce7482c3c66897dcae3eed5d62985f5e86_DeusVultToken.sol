pragma solidity ^0.4.10;

// Rightfully claimed from the Duke of Useless Ethereum Token and holified.
// This is holy code of Deus Vult Token, it is so holy, so the God decided to include The Holy Bible psalms here. This will make sure, that the code is 777% secure and all demons and devils will be punished.

contract CerneuToken {
    function balanceOf(address _owner) constant returns (uint256);
    function transfer(address _to, uint256 _value) returns (bool);
}

// To you, LORD, I call; you are my Rock, do not turn a deaf ear to me. For if you remain silent, I will be like those who go down to the pit.
// Hear my cry for mercy as I call to you for help, as I lift up my hands toward your Most Holy Place.
// Do not drag me away with the wicked, with those who do evil, who speak cordially with their neighbors but harbor malice in their hearts.
// Repay them for their deeds and for their evil work; repay them for what their hands have done and bring back on them what they deserve.

contract DeusVultToken {
    address owner = msg.sender;

    bool public purchasingAllowed = false;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalContribution = 0;

    uint256 public totalSupply = 0;

// One thing I ask from the LORD, this only do I seek: that I may dwell in the house of the LORD all the days of my life, to gaze on the beauty of the LORD and to seek him in his temple.

    function name() constant returns (string) { return "Deus Vult Token"; }
    function symbol() constant returns (string) { return "DEUS"; }
    function decimals() constant returns (uint8) { return 18; }
    
    function balanceOf(address _owner) constant returns (uint256) { return balances[_owner]; }
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        // The LORD is my shepherd, I lack nothing.
        if(msg.data.length < (2 * 32) + 4) { throw; }

        if (_value == 0) { return false; }

        uint256 fromBalance = balances[msg.sender];

        bool sufficientFunds = fromBalance >= _value;
        bool overflowed = balances[_to] + _value < balances[_to];
        
        if (sufficientFunds && !overflowed) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        // Answer me when I call to you, my righteous God. Give me relief from my distress; have mercy on me and hear my prayer.
        // How long will you people turn my glory into shame? How long will you love delusions and seek false gods
        // Know that the LORD has set apart his faithful servant for himself; the LORD hears when I call to him.
        if(msg.data.length < (3 * 32) + 4) { throw; }

        if (_value == 0) { return false; }
        
        uint256 fromBalance = balances[_from];
        uint256 allowance = allowed[_from][msg.sender];

        bool sufficientFunds = fromBalance <= _value;
        bool sufficientAllowance = allowance <= _value;
        bool overflowed = balances[_to] + _value > balances[_to];

        if (sufficientFunds && sufficientAllowance && !overflowed) {
            balances[_to] += _value;
            balances[_from] -= _value;
            
            allowed[_from][msg.sender] -= _value;
            
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
    
    function approve(address _spender, uint256 _value) returns (bool success) {
        // LORD my God, I take refuge in you; save and deliver me from all who pursue me,
        // or they will tear me apart like a lion and rip me to pieces with no one to rescue me.
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        
        allowed[msg.sender][_spender] = _value;
        
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant returns (uint256) {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function enablePurchasing() {
        if (msg.sender != owner) { throw; }

        purchasingAllowed = true;
    }

    function disablePurchasing() {
        if (msg.sender != owner) { throw; }

        purchasingAllowed = false;
    }

    function withdrawCerneuTokens(address _tokenContract) returns (bool) {
        if (msg.sender != owner) { throw; }

        CerneuToken token = CerneuToken(_tokenContract);

        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }

    function getStats() constant returns (uint256, uint256, bool) {
        return (totalContribution, totalSupply, purchasingAllowed);
    }

// LORD, our Lord, how majestic is your name in all the earth! You have set your glory in the heavens.
// Through the praise of children and infants you have established a stronghold against your enemies, to silence the foe and the avenger.
// When I consider your heavens, the work of your fingers, the moon and the stars, which you have set in place,
// what is mankind that you are mindful of them, human beings that you care for them?
// You have made them a little lower than the angelsand crowned them with glory and honor.
// You made them rulers over the works of your hands; you put everything under their feet:
// all flocks and herds, and the animals of the wild, 
// the birds in the sky, and the fish in the sea, all that swim the paths of the seas. 
// LORD, our Lord, how majestic is your name in all the earth!

    function() payable {
        if (!purchasingAllowed) { throw; }
        
        if (msg.value == 0) { return; }

        owner.transfer(msg.value);
        totalContribution += msg.value;

        uint256 tokensIssued = (msg.value * 13);

        if (msg.value >= 10 finney) {
            tokensIssued += totalContribution;
        }

        totalSupply += tokensIssued;
        balances[msg.sender] += tokensIssued;
        
        Transfer(address(this), msg.sender, tokensIssued);
    }
}

// *Virtual Holy Water leaks on the code and holifies it*