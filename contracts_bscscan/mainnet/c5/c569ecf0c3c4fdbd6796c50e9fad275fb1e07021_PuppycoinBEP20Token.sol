/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

// SPDX-License-Identifier: UNLISCENSED

pragma solidity 0.8.4;


/**
 * @title PuppyCoin
 */
 
contract PuppycoinBEP20Token {
    string public name = "PuppyCoin";
    string public symbol = "PPC";
    uint256 public totalSupply = 1000000000000000000000000000; // 10 billion tokens
    uint8 public decimals = 18;
    
    /**
     * when `balioa` tokenak kontu batetik (` tik`) mugitzen dira
      * beste bat (`to`).
      *
      * Kontuan izan `balioa` zero izan daitekeela.
     */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

     /**
     * Jabearentzako `gastu` baten hobaria ezartzen denean igortzen da
      * {onartzeko} deia. `balioa` hobari berria da.
     */
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    /**
     * Msg.sender-i lehendik dauden token guztiak ematen dizkion eraikitzailea.
     */
    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

     /**
     * `Zenbatekoa 'tokenak deitzailearen kontutik" hartzailea "izatera eramaten ditu.
      *
      * Balio boolear bat ematen du eragiketak arrakasta izan duen ala ez adierazten duena.
      *
      * {Transfer} gertaera igortzen du.
     */
    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
     /**
     * `Zenbatekoa` ezartzen du deitzailearen token gaineko` gastuaren` hobari gisa.
      *
      * Balio boolear bat ematen du eragiketak arrakasta izan duen ala ez adierazten duena.
      *
      * GARRANTZITSUA: Kontuz metodo honekin hobari bat aldatzeak arriskua dakarrela
      * norbaitek hobari zaharra eta berria erabil ditzala zoritxarrez
      * transakzio eskaerak. Lasterketa hau arintzeko irtenbide posible bat
      * baldintza da lehenik gastuaren hobaria 0ra murriztea eta
      * ondoren nahi duzun balioa:
      * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
      *
      * {Onarpena} gertaera igortzen du.
     */

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

   /**
      * `Zenbatekoa 'tokenak igorletik` hartzailea` izatera eramaten ditu
      * hobariaren mekanismoa. Orduan, "zenbatekoa" kentzen zaio deitzaileari
      * hobaria.
      *
      * Balio boolear bat ematen du eragiketak arrakasta izan duen ala ez adierazten duena.
      *
      * {Transfer} gertaera igortzen du.
      */
      
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}