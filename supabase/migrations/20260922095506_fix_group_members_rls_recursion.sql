-- Fix "infinite recursion detected in policy for relation group_members"
-- (Postgres 42P17). gm_select_member's USING clause queried group_members
-- from within its own policy; Postgres re-applies group_members' RLS to
-- that inner subquery, which invokes the same policy again, forever.
-- groups_select_member hit the same wall indirectly, since its subquery
-- also reads group_members and so still goes through gm_select_member.
--
-- Fix: a SECURITY DEFINER helper function. Its body runs as the function
-- owner (which owns group_members and isn't subject to its own RLS by
-- default, since FORCE ROW LEVEL SECURITY was never set), so the
-- membership check no longer re-triggers the policy it's used inside.

CREATE OR REPLACE FUNCTION is_group_member(p_group_id UUID, p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM group_members WHERE group_id = p_group_id AND user_id = p_user_id
  );
$$;

DROP POLICY IF EXISTS "gm_select_member" ON group_members;
CREATE POLICY "gm_select_member" ON group_members FOR SELECT
  USING (is_group_member(group_id, auth.uid()));

DROP POLICY IF EXISTS "groups_select_member" ON groups;
CREATE POLICY "groups_select_member" ON groups FOR SELECT
  USING (is_group_member(id, auth.uid()));
