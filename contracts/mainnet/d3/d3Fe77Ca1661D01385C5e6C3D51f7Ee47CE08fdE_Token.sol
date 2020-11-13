pragma solidity >=0.4.16 <0.7.0;

import "./ERC20Interface.sol";

contract MyToken is ERC20Interface {

    uint256 constant private MAX_UINT256 = 2 ** 256 - 1;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    /// Nazwa naszego tokenu, zostanie zdefiniowana przy pomocy konstruktora
    string public name;

    /// Punkty dziesiętne naszego tokenu. Jeżeli ustalimy totalSupply na 1 oraz decimals na 18, to reprezentacyjna
    /// wartość tokenu przyjmie formę 1000000000000000000 (1 * 10^18)
    uint8 public decimals;

    /// Trzy lub czterocyfrowy symbol określający naszą token
    string public symbol;

    /// Konstruktor wykonany przy wgraniu kontraktu do sieci. Wszystkie tokeny zostaną przypisane do konta,
    /// które będzie odpowiadać za deployment (właściciel kontraktu).
    function MyToken(uint256 _initialAmount, string _tokenName, uint8 _decimalUnits, string _tokenSymbol) public {
        symbol = _tokenSymbol;
        name = _tokenName;
        decimals = _decimalUnits;
        totalSupply = _initialAmount * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
    }

    /// Sprawdzenie balansu danego użytkownika
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    /// Przetransferowanie środków na inne portfel
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /// Umożliwienie przelania środków z jednego portfela na drugi przez osobę trzecią
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        Transfer(_from, _to, _value);
        return true;
    }

    /// Zgoda na to, by wskazana osoba mogła przelać nasze środki z limitem maksymalnej wartości
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    // Funkcja która powoduje, że kontrakt nie przyjmie środków w postaci czystego przelewu ETH.
    function() public payable {
        revert();
    }
}
