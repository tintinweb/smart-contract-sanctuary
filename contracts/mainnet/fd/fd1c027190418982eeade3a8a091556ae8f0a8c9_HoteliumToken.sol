pragma solidity ^0.5.1;

contract transferable { function transfer(address to, uint256 value) public returns (bool); }
contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) public; }

contract HoteliumToken {
    string public name = "Hotelium";
    string public symbol = "HTL";
    uint8 public decimals = 8;
    address public owner;
    uint256 public _totalSupply = 49000000000000000;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Burn(address indexed from, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor() public {
        balances[0xf115c4bE4C298cA9166BBB7C1922435fd3E87084] = 40000000000000000;

        balances[0x8d68e0FBea987B480C81EcB2B67B5f106786747f] = 1000000000000000;
        balances[0x34c1baf2bF700C963AE21090236D90CA9f4a317e] = 1000000000000000;
        balances[0x9FDcA6eDd5C0B5eD9ed5131835Cee0413EF5b91f] = 1000000000000000;
        balances[0xb150864c2B4F7181a8d72bA10ED6Ad834BFcEBf1] = 1000000000000000;
        balances[0x53C7e935350615DCad91957C64F070d950a1a410] = 1000000000000000;
        balances[0x63346d5b073310a704440802C1b5666a7F57b553] = 1000000000000000;
        balances[0x9b150527964699A6DB9dDB0006432208Cd41d594] = 1000000000000000;
        balances[0xC09118e41F08B317d2aDa4f5433ebFCEd83E490A] = 1000000000000000;


        balances[0xe3Ea7413D30E1fdB6Ab4f32ecDBa3F6eaC925401] = 190000000000000;
        balances[0x0B0F2674401cE36816452476f19f004a1b1E68c2] = 190000000000000;
        balances[0xB439dacB0Be7B5efEaf1f28F30c39F8e25239195] = 190000000000000;
        balances[0xD6Cf1038638E1C4F021E979B0e8cAc660a523Be5] = 190000000000000;
        balances[0xB8B4E2cF8314Dad106bADB28C2cfe735FC7616fD] = 190000000000000;


        balances[0x97b9155feE365cCD805aE080d986DB0E43a9C0E9] = 50000000000000;
        owner = 0xf115c4bE4C298cA9166BBB7C1922435fd3E87084;
        
        emit Transfer(address(0), 0xf115c4bE4C298cA9166BBB7C1922435fd3E87084, 40000000000000000);

        emit Transfer(address(0), 0x8d68e0FBea987B480C81EcB2B67B5f106786747f, 1000000000000000);
        emit Transfer(address(0), 0x34c1baf2bF700C963AE21090236D90CA9f4a317e, 1000000000000000);
        emit Transfer(address(0), 0x9FDcA6eDd5C0B5eD9ed5131835Cee0413EF5b91f, 1000000000000000);
        emit Transfer(address(0), 0xb150864c2B4F7181a8d72bA10ED6Ad834BFcEBf1, 1000000000000000);
        emit Transfer(address(0), 0x53C7e935350615DCad91957C64F070d950a1a410, 1000000000000000);
        emit Transfer(address(0), 0x63346d5b073310a704440802C1b5666a7F57b553, 1000000000000000);
        emit Transfer(address(0), 0x9b150527964699A6DB9dDB0006432208Cd41d594, 1000000000000000);
        emit Transfer(address(0), 0xC09118e41F08B317d2aDa4f5433ebFCEd83E490A, 1000000000000000);


        emit Transfer(address(0), 0xe3Ea7413D30E1fdB6Ab4f32ecDBa3F6eaC925401, 190000000000000);
        emit Transfer(address(0), 0x0B0F2674401cE36816452476f19f004a1b1E68c2, 190000000000000);
        emit Transfer(address(0), 0xB439dacB0Be7B5efEaf1f28F30c39F8e25239195, 190000000000000);
        emit Transfer(address(0), 0xD6Cf1038638E1C4F021E979B0e8cAc660a523Be5, 190000000000000);
        emit Transfer(address(0), 0xB8B4E2cF8314Dad106bADB28C2cfe735FC7616fD, 190000000000000);

        emit Transfer(address(0), 0x97b9155feE365cCD805aE080d986DB0E43a9C0E9, 50000000000000);
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

    function totalSupply() public view returns (uint256 supply) {
        return _totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (_to == address(0x0)) return false;
        if (balances[msg.sender] < _value) return false;
        if (balances[_to] + _value < balances[_to]) return false;
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }        

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (_to == address(0x0)) return false;
        if (balances[_from] < _value) return false;
        if (balances[_to] + _value < balances[_to]) return false;
        if (_value > allowances[_from][msg.sender]) return false;
        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        if (balances[msg.sender] < _value) return false;
        balances[msg.sender] -= _value;
        _totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        if (balances[_from] < _value) return false;
        if (_value > allowances[_from][msg.sender]) return false;
        balances[_from] -= _value;
        _totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }

    function transferAnyERC20Token(address tokenAddress, uint tokens) public returns (bool success) {
        return transferable(tokenAddress).transfer(owner, tokens);
    }
}