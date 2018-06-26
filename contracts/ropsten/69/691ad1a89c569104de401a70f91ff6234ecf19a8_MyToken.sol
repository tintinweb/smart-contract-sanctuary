pragma solidity ^0.4.18;
contract MyToken {
   mapping (address => uint256) public balance;
   string public name;
   string public symbol;
   uint8 public decimals;
   uint256 public totalSupply;

   event Transfer(address indexed from, address indexed to, uint256 value);
   /* Khởi tạo hợp đ&#244;̀ng ghi lại toàn bộ lượng token được cung c&#226;́p ban đ&#226;̀u,
      quy&#234;̀n sở hữu thuộc v&#234;̀ người khởi tạo*/

   function MyToken(uint256 initialSupply, string tokenName,
   string tokenSymbol, uint8 decimalUnits) {
       // Gán quy&#234;̀n sở hữu toàn bộ lượng token ban đ&#226;̀u cho người khởi tạo
       balance[msg.sender] = initialSupply;
         // Gán tên cho token
        name = tokenName;
        // Gán kí hiệu cho token
        symbol = tokenSymbol;
        // Gán đơn vị chia
        decimals = decimalUnits;
        // Gán t&#244;̉ng lượng cung lớn nh&#226;́t
        totalSupply = initialSupply;
    }

    /* Phương thức chuy&#234;̉n token*/
    function transfer(address _to, uint256 _value) {
       // Ki&#234;̉m tra s&#244;́ dư của người kích hoạt
        require(balance[msg.sender] >= _value);
        // Ki&#234;̉m tra tràn s&#244;́
        require(balance[_to] + _value >= balance[_to]);
        // Trừ s&#244;́ dư của người gửi
        balance[msg.sender] -= _value;
        // Tăng s&#244;́ dư của người nhận
        balance[_to] += _value;
        /* Ghi log lại các thông tin */

        Transfer(msg.sender, _to, _value);
    }

    /* Truy v&#226;́n tên token*/
    function name() constant returns (string) {
     return name;
    }

    /* Truy v&#226;́n kí hiệu token*/
    function symbol() constant returns (string) {
     return symbol;
    }

    /* Truy v&#226;́n độ chia nhỏ nh&#226;́t*/
    function decimals() constant returns (uint8) {
     return decimals;
    }

    /* Truy v&#226;́n lượng cung Token t&#244;́i đa*/
    function totalSupply() constant returns (uint256) {
     return totalSupply;
    }
    
    /* Truy v&#226;́n s&#244;́ dư*/
    function balanceOf(address _owner)  constant returns (uint256) {
     return balance[_owner];
    }
}