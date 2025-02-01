// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract VotingToken is ERC20, ERC20Burnable {
    address payable owner;
    uint8 private _decimals;
    mapping(address => uint256) private _freezingBalance;
    mapping(address => bool) public isBlackListed;

    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier isBlackList(address _evilUser, uint256 _amount) {
        require(
            _amount <= balanceOf(_evilUser) - _freezingBalance[_evilUser] &&
                !getBlackListStatus(_evilUser)
        );
        _;
    }

    constructor(
        uint256 initialSupply,
        string memory name,
        string memory symbol,
        uint8 decimal,
        address _owner
    ) ERC20(name, symbol) {
        _decimals = decimal;
        _mint(payable(_owner), _convertToken(initialSupply));
        owner = payable(_owner);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function _convertToken(uint256 _value) private view returns (uint256) {
        return _value * 10 ** _decimals;
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function getFreezingAmount(address _maker) external view returns (uint256) {
        return _freezingBalance[_maker];
    }

    function freezingToken(
        address _evilUser,
        uint256 _amount
    ) public onlyOwner {
        require(
            balanceOf(_evilUser) >= _amount &&
                balanceOf(_evilUser) - _freezingBalance[_evilUser] >= _amount
        );
        _freezingBalance[_evilUser] = _freezingBalance[_evilUser] + _amount;
    }

    function redeemToken(
        address _clearedUser,
        uint256 _amount
    ) public onlyOwner {
        require(_freezingBalance[_clearedUser] >= _amount);
        _freezingBalance[_clearedUser] =
            _freezingBalance[_clearedUser] -
            _amount;
    }

    function transfer(
        address to,
        uint256 amount
    ) public override isBlackList(_msgSender(), amount) returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override isBlackList(from, amount) returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function burn(
        uint256 amount
    ) public override isBlackList(_msgSender(), amount) {
        _burn(_msgSender(), amount);
    }

    function burnFrom(
        address account,
        uint256 amount
    ) public override isBlackList(account, amount) {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function addBlackList(address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
    }

    function removeBlackList(address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
    }

    function getBlackListStatus(address _maker) public view returns (bool) {
        return isBlackListed[_maker];
    }
}
