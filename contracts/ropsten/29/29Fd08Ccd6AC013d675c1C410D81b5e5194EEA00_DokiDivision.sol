// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";
import "./ERC721PresetMinterPauserAutoIdModified.sol";
import "./Address.sol";

contract DokiDivision is ERC721PresetMinterPauserAutoId {
  using Address for address;

  bool public presaleIsActive = false;
  bool public saleIsActive = false;
  uint256 public MAX_SUPPLY = 10000;
  uint256 public MAX_PRESALE_SUPPLY = 1500;
  uint public DOKI_PRICE = 75000000000000000 wei;
  uint public MAX_PER_WALLET = 10;

  uint256 private PRESALE_SHAREHOLDERS = 3;
  uint256 private SALE_SHAREHOLDERS = 2;

  address[3] private presaleShareholders;
  uint[3] private presaleShares;

  address[2] private shareholders;
  uint[2] private shares;


  mapping(address => uint256) public minted;
  mapping(address => uint256) public whitelisted;

  event PaymentDisbursed(address to, uint256 amount);
  event Airdrop(address to);
  event PresaleMint(address to, uint256 amount);
  event GeneralMint(address to, uint256 amount);
  event Whitelist(address to, uint256 amount);

  constructor(

    string memory _name,
    string memory _symbol,
    string memory _baseURI

  ) ERC721PresetMinterPauserAutoId(_name, _symbol, _baseURI) {

    shareholders[0] = 0x866aE03EC5F52452Ac527023BcE1E94b347099A5;
    shareholders[1] = 0x46169Da5A6056b6Fcb64412c27097418cc163667;

    shares[0] = 9800;
    shares[1] = 200;


    presaleShareholders[0] = 0x866aE03EC5F52452Ac527023BcE1E94b347099A5;
    presaleShareholders[1] = 0x49282E5E05fE59A724641eE867641b5883C02E58;
    presaleShareholders[2] = 0x46169Da5A6056b6Fcb64412c27097418cc163667;

    presaleShares[0] = 9350;
    presaleShares[1] = 450;
    presaleShares[2] = 200;

  }


  function flipPresale(bool status) public onlyOwner() {

    if (status == false) {
      disburseFunds();
    }

    presaleIsActive = status;

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

  function setMaxPresaleSupply(uint256 max) public onlyOwner() {
    MAX_PRESALE_SUPPLY = max;

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
        emit Whitelist(users[i], allowedMint[i]);
    }
  }


  function disburseFunds() public onlyOwner {

    uint256 totalShares = 10000;
    uint256 amount = address(this).balance;

    if (presaleIsActive && !saleIsActive ) {
      for (uint256 i = 0; i < PRESALE_SHAREHOLDERS; i++) {
          uint256 payment = amount * presaleShares[i] / totalShares;
          Address.sendValue(payable(presaleShareholders[i]), payment);
          emit PaymentDisbursed(presaleShareholders[i], payment);
      }
    }

    else if (!presaleIsActive && saleIsActive ) {
      for (uint256 i = 0; i < SALE_SHAREHOLDERS; i++) {
          uint256 payment = amount * shares[i] / totalShares;
          Address.sendValue(payable(shareholders[i]), payment);
          emit PaymentDisbursed(shareholders[i], payment);
      }
    }

  }

  function airdrop(address[] memory winners) public onlyOwner {
      require(totalSupply() + winners.length < MAX_SUPPLY, "Airdropped amount must keep total supply under MAX SUPPLY");
      for (uint256 i = 0; i < winners.length; i++) {
          mint(winners[i]);
          emit Airdrop(winners[i]);
      }
  }


  function mintPresale(uint256 _amount) external payable {
      require(_amount > 0, "Mint amount must be positive integer");
      require(presaleIsActive,"Presale must be active");
      require(!Address.isContract(msg.sender), "Contracts are not allowed to mint");
      require(whitelisted[msg.sender] > 0, "Must be on the whitelist");
      require(minted[msg.sender] + _amount <= MAX_PER_WALLET, "Purchase would exceed max tokens for presale");
      require(minted[msg.sender] + _amount <= whitelisted[msg.sender], "Purchase would exceed max tokens whitelisted for presale");
      require(totalSupply() + _amount <= MAX_PRESALE_SUPPLY, "Purchase would exceed max supply allotted for presale");
      require(msg.value >= DOKI_PRICE * _amount, "Ether value sent is not correct");


      for(uint i; i < _amount; i++){
          mint(msg.sender);
      }

      minted[msg.sender] += _amount;
      emit PresaleMint(msg.sender, _amount);
  }


  function mintSale(uint256 _amount) external payable {
      require(_amount > 0, "Mint amount must be positive integer");
      require(!presaleIsActive,"Presale cannot be active during general sale");
      require(saleIsActive, "Sale must be active");
      require(!Address.isContract(msg.sender), "Contracts are not allowed to mint");
      require(minted[msg.sender] + _amount <= MAX_PER_WALLET, "Purchase would exceed max tokens per wallet");
      require(totalSupply() + _amount <= MAX_SUPPLY, "Purchase would exceed max supply of tokens");
      require(msg.value >= DOKI_PRICE * _amount, "Ether value sent is not correct");


      for(uint i; i < _amount; i++) {
          mint(msg.sender);
      }

      minted[msg.sender] += _amount;
      emit GeneralMint(msg.sender, _amount);
  }


}