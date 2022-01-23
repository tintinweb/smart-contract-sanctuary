/**
 *Submitted for verification at polygonscan.com on 2022-01-23
*/

// SPDX-License-Identifier: MIT
//オープンソースのMITライセンスです。ご自由にお使いください

//バージョン指定
pragma solidity ^0.8.0;

//ERC20規格を読み込むための準備
interface IERC20 {
    //標準的なインタフェース
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    //追加で呼び出したい関数を指定しています
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}



contract JPYC_Example {

    //上で定義したERC20規格を呼び出すための仕組み(インタフェース)です
    IERC20 public jpyc;

    //貯金箱持ち主のアドレスです
    address owner;

    constructor() {
         //スマートコントラクトの作成者を貯金箱の持ち主に設定します
         owner = msg.sender;
         
         //Ethereum NetworkのJPYC
         //jpyc = IERC20(0x2370f9d504c7a6e775bf6e14b3f12846b594cd53); コメントアウト中
         
         //Polygon Network(matic)のJPYC
         jpyc = IERC20(0x6AE7Dfc73E0dDE2aa99ac063DcF7e8A63265108c);
         
         //xDai NetworkのJPYC
         //jpyc = IERC20(0x417602f4fbdd471A431Ae29fB5fe0A681964C11b);  コメントアウト中
    } 

    //名前を確認する関数です
    function getname() public view returns (string memory){
        return jpyc.name();
    }

    //シンボル(JPYC)を確認する関数です
    function getsymbol() public view returns (string memory){
        return jpyc.symbol();
    }

    //貯金箱に入っている金額を確認する関数です
    function jpycAmount() public view returns (uint) {
        return jpyc.balanceOf(address(this)) / 10 ** 18;
    }

    //貯金箱からの送金を許可する関数です
    function approveJpycFromContract() public {
        jpyc.approve( address(this) , jpyc.balanceOf(address(this)) );
    }

    //貯金箱からの出金をする関数です
    function withdraw_jpyc() public {
        //貯金箱の持ち主だけが呼び出せるように『require』で指定しています
        require(msg.sender == owner);
        jpyc.transferFrom(address(this) , owner , jpyc.balanceOf(address(this)) );
    }
    
}