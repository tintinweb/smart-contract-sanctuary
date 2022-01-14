/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

contract AutoAppServer{
    address private owner; //创建者
    bool public isEnableApp;//是否激活应用
    AppVersion[] private versions;//版本记录
    Notice[] public notices; //通知记录
    mapping(string => Cmd) public commands;

    /**
     * 校验是否是合约发布者
     */
    modifier isOwner() {
        require(owner == msg.sender);
         _;
    }

    constructor() payable{
        owner = msg.sender;
        isEnableApp = true;
    }

    //版本信息实体
    struct AppVersion{
        uint version;
        string describe;
        string url;
    }

    //通知信息实体
    struct Notice{
        uint time;
        string title;
        string content;
    }

    //命令消息实体
    struct Cmd{
        uint startTime;
        uint endTime;
        string command;
        string extra;
        bool enable;
    }

    //设置是否激活应用
    function setEnableApp(bool isEnable) isOwner public {
        isEnableApp = isEnable;
    }

    //添加版本信息
    function addAppVersion(uint _version, string memory _describe, string memory _url) isOwner public{
        versions.push(AppVersion({
            version: _version,
            describe: _describe,
            url: _url
        }));
    }

    //查询版本信息,对外
    function getAppVersion() view public returns(uint, string memory,string memory){
        uint index = versions.length-1;
        AppVersion storage versionBean = versions[index];
        return (versionBean.version,versionBean.describe,versionBean.url);
    }

    //添加通知信息
    function addNotice(uint _time,string memory _title, string memory _content) isOwner public{
        notices.push(Notice({
            time: _time,
            title: _title,
            content: _content
        }));
    }

    //获取通知
    function getNotice(uint _index) view public returns(uint,string memory,string memory){
        Notice storage notice = notices[_index];
        return (notice.time,notice.title,notice.content);
    }

    //获取通知数量
    function getNoticeCount() view public returns(uint){
        return notices.length;
    }

    //添加命令
    function addCommands(string memory commandType,uint _startTime,uint _endTime,string memory _command,string memory _extra,bool _enable) isOwner public {
        commands[commandType] = Cmd({
            startTime: _startTime,
            endTime: _endTime,
            command: _command,
            extra: _extra,
            enable: _enable
        });
    }

    //获取命令
    function getCommands(string memory commandType) view public returns(uint,uint,string memory,string memory,bool){
        Cmd storage cmd = commands[commandType];

        return (cmd.startTime,cmd.endTime,cmd.command,cmd.extra,cmd.enable);
    }

    //销毁合约
    function kill() isOwner public {
         selfdestruct(payable(msg.sender));
    }
}