class ViewModel extends SqRootScript
{
    function OnFrobInvBegin() {
    }

    function OnFrobToolBegin() {
    }

    function OnInvSelect() {
        Weapon.Equip(self);
    }

    function OnInvDeSelect() {
        Weapon.UnEquip(self);
    }
}
