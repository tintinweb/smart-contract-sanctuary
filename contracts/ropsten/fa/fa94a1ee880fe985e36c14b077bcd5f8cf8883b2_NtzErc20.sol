pragma solidity ^0.4.18;

/**
 * Jika ingin validasi, maka yang digunakan adalah compiler 0.4.22
 *
 * Checklist
 * 1. Ketika mengirim, saldo pengirim berkurang dan saldo penerima bertambah
 *
 */

contract NtzErc20 {

    // Variabel publik yang bisa diakses oleh semua orang secara langsung
    string  public name = &#39;NtzToken&#39;;
    string  public symbol = &#39;NTZ&#39;;
    uint8   public decimals = 18; // 18 decimals sangat disarankan dalam smartcontract/ethereum
    uint256 public totalSupply = 1000000000 * 10 ** uint256(decimals);

    // Pemilik token
    address public owner;

    // Array balance untuk semua address dalam contract ini
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // Public event untuk memberikan notifikasi kepada semua clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor () public {
        owner                 = msg.sender;
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
    }
}