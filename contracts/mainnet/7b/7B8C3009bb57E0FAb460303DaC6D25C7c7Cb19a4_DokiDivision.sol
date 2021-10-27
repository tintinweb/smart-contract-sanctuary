// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";
import "./ERC721PresetMinterPauserAutoIdModified.sol";
import "./Address.sol";

contract DokiDivision is ERC721PresetMinterPauserAutoId {
  using Address for address;


  bool public saleIsActive = false;
  uint256 public MAX_SUPPLY = 10000;
  uint public DOKI_PRICE = 75000000000000000 wei;
  uint public MAX_PER_WALLET = 10;

  uint256 private SHAREHOLDERS = 3;

  address[3] private shareholders;
  uint[3] private shares;
  uint[3] private saleAccrued;
  uint[3] private saleCap;

  mapping(address => uint256) public minted;
  mapping(address => uint256) public whitelisted;

  constructor(

    string memory _name,
    string memory _symbol,
    string memory _baseURI

  ) ERC721PresetMinterPauserAutoId(_name, _symbol, _baseURI) {

    shareholders[0] = 0x504fE78591F69eBa04E87b9c7F0802f973Ca146D; //Niqhtmare
    shareholders[1] = 0x49282E5E05fE59A724641eE867641b5883C02E58; //Foudres
    shareholders[2] = 0x80d9629b4D13B9e3176bA1a6daCACF432cfaAd8a; //Slothrop

    shares[0] = 9050;
    shares[1] = 450;
    shares[2] = 500;

    saleAccrued[0] = 0;
    saleAccrued[1] = 0;
    saleAccrued[2] = 0;

    saleCap[0] = 0;
    saleCap[1] = 5000000000000000000;
    saleCap[2] = 0;

  }


  function flipSale(bool status) public onlyOwner() {

    if (status == false) {
      disburseFunds();
    }

    saleIsActive = status;

  }

  function setMaxSupply(uint256 max) public onlyOwner() {
    MAX_SUPPLY = max;

  }


  function setMaxMintPerWallet(uint256 max) public onlyOwner() {
    MAX_PER_WALLET = max;

  }

  function setMintPrice(uint256 priceInWei) public onlyOwner() {
    DOKI_PRICE = priceInWei;

  }

  function setWhitelistAddress (address[] memory users, uint[] memory allowedMint) public onlyOwner {
    for (uint i = 0; i < users.length; i++) {
        whitelisted[users[i]] = allowedMint[i];
    }
  }


  function disburseFunds() public onlyOwner {

    uint256 totalShares = 10000;
    uint256 amount = address(this).balance;

    for (uint256 i = 0; i < SHAREHOLDERS; i++) {

        uint256 payment = amount * shares[i] / totalShares;

        if (saleCap[i] > 0) {

          if ((saleAccrued[i] + payment) > saleCap[i]) {

            if (saleCap[i] - saleAccrued[i] > 0) {

              payment = saleCap[i] - saleAccrued[i];
              Address.sendValue(payable(shareholders[i]), payment);
              saleAccrued[i] += payment;
            }
            else {
              // if cap is hit, send funds to Niqhtmare

              Address.sendValue(payable(shareholders[0]), payment);

            }
          } else {

            Address.sendValue(payable(shareholders[i]), payment);
            saleAccrued[i] += payment;
          }
        } else {

            Address.sendValue(payable(shareholders[i]), payment);
            saleAccrued[i] += payment;
        }
    }

  }

  function airdrop(address[] memory winners) public onlyOwner {
      require(totalSupply() + winners.length < MAX_SUPPLY, "Airdropped amount must keep total supply under MAX SUPPLY");
      for (uint256 i = 0; i < winners.length; i++) {
          mint(winners[i]);
      }
  }


  function mintSale(uint256 _amount) external payable {
      require(_amount > 0, "Mint amount must be positive integer");
      require(saleIsActive, "Sale must be active");
      require(!Address.isContract(msg.sender), "Contracts are not allowed to mint");
      require(minted[msg.sender] + _amount <= MAX_PER_WALLET, "Purchase would exceed max tokens per wallet");
      require(totalSupply() + _amount <= MAX_SUPPLY, "Purchase would exceed max supply of tokens");
      require(msg.value >= DOKI_PRICE * _amount, "Ether value sent is not correct");


      for(uint i; i < _amount; i++) {
          mint(msg.sender);
      }

      minted[msg.sender] += _amount;
  }


}