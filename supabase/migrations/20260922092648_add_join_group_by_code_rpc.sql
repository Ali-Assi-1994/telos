-- Add join_group_by_code RPC: lets an authenticated user join a group using
-- its 6-character invite code.
--
-- This has to be a SECURITY DEFINER RPC because the groups_select_member RLS
-- policy only allows a user to SELECT a group they already belong to -- a
-- client has no way to resolve an invite code to a group id before
-- membership exists. This function looks the group up by code, validates
-- it, and inserts the membership atomically, following the same
-- auth.uid()-checked pattern as the other SECURITY DEFINER RPCs
-- (see 20260921170059_restrict_security_definer_rpcs.sql).

CREATE OR REPLACE FUNCTION join_group_by_code(p_invite_code TEXT, p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_group groups%ROWTYPE;
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RETURN jsonb_build_object('success', FALSE, 'error', 'Not authorized');
  END IF;

  SELECT * INTO v_group FROM groups WHERE invite_code = UPPER(TRIM(p_invite_code));

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', FALSE, 'error', 'Invalid invite code');
  END IF;

  IF EXISTS (
    SELECT 1 FROM group_members WHERE group_id = v_group.id AND user_id = p_user_id
  ) THEN
    RETURN jsonb_build_object('success', FALSE, 'error', 'You are already in this group');
  END IF;

  INSERT INTO group_members (group_id, user_id, role) VALUES (v_group.id, p_user_id, 'member');

  RETURN jsonb_build_object(
    'success', TRUE,
    'group', jsonb_build_object(
      'id', v_group.id,
      'name', v_group.name,
      'description', v_group.description,
      'invite_code', v_group.invite_code,
      'created_by', v_group.created_by,
      'created_at', v_group.created_at,
      'updated_at', v_group.updated_at
    )
  );
END;
$$;
