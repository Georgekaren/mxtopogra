CREATE OR REPLACE FUNCTION SF_GET_NODE_INFO_BY_ID(inmethonId IN VARCHAR2,intype IN VARCHAR2 ,inx number,iny number) RETURN clob IS

  /******************************************************************************
     NAME:       SF_GET_NODE_INFO_BY_ID
     PURPOSE:    通过资源ID查询下级资源节点

     REVISIONS:
     Ver        Date        Author           Description
     ---------  ----------  ---------------  ------------------------------------
     1.0        2017-12-20  SHEN.ZHI          建立函数
  ******************************************************************************
  ******************************************************************************/

  v_return clob;
  v_resId varchar(30);
  v_res_type_id varchar(30);
  v_has_cnt number;
  
  v_r_heard clob;
  v_r_body clob;
  
cursor c_get_odf_by_eqpid(v_eqpId varchar2 ) is
select
  r.rack_name,r.rack_id
 from rme_optic_line l,rme_port a ,rme_optic_term t,rme_rack r
where l.a_id=a.port_id  and a.super_res_id=v_eqpId
and l.z_id=t.term_id and t.super_res_id=r.rack_id
and l.delete_state='0' and a.delete_state='0' and t.delete_state='0' and r.delete_state='0'
union
select
   r.rack_name,r.rack_id
 from rme_optic_line l,rme_port a ,rme_optic_term t,rme_rack r
where l.z_id=a.port_id  and a.super_res_id=v_eqpId
and l.a_id=t.term_id and t.super_res_id=r.rack_id
and l.delete_state='0' and a.delete_state='0' and t.delete_state='0' and r.delete_state='0'
;
---根据OLT查询一级OBD
---查询一级OBD下二级OBD信息
cursor c_get_obd1_by_olteqpid(v_eqpId varchar2 ) is
select distinct a.z_eqp_id eqp_id,sf_get_res_name(a.z_eqp_id) eqp_name
from opt_road a where a.delete_state='0' and a.a_eqp_id =v_eqpId ;


---根据ODF找光交
cursor c_get_cnt_by_eqpid(v_odfId varchar2 ) is
select d.cnt_box_id,d.cnt_box_name,'703' restype
 from rme_optic_term t1, opt_logic_opt_pair c,opt_connect_box d,rme_optic_term t
  where t1.term_id=c.z_term  and c.a_term=t.term_id and t.super_res_id=d.cnt_box_id
        and t1.super_res_id=v_odfId     and c.delete_state='0' and t1.delete_state='0' and t.delete_state='0'
 union
  select d.cnt_box_id,d.cnt_box_name,'703' restype
 from rme_optic_term t1, opt_logic_opt_pair c,opt_connect_box d,rme_optic_term t
  where t1.term_id=c.a_term  and c.z_term=t.term_id and t.super_res_id=d.cnt_box_id
        and t1.super_res_id=v_odfId    and c.delete_state='0' and t1.delete_state='0' and t.delete_state='0'
;

--根据光交找OBD（或下级光交 新增18-1-19）
cursor c_get_obd_by_eqpid(v_cntId varchar2) is
select c.super_res_id eqp_id,sf_get_eqp_name(c.super_res_id) eqp_name,c.port_id,a.term_no,c.port_no,'2530' restype from rme_optic_term a,rme_optic_line b,rme_port c
 where a.super_res_id=v_cntId and a.term_id=b.a_id and c.super_res_type=2530
       and b.z_id=c.port_id and a.delete_state='0' and b.delete_state='0' and c.delete_state='0' and c.purpose='24110215'
union
select c.super_res_id eqp_id,sf_get_eqp_name(c.super_res_id) eqp_name,c.port_id,a.term_no,c.port_no,'2530' restype from rme_optic_term a,rme_optic_line b,rme_port c
 where a.super_res_id=v_cntId and a.term_id=b.z_id and c.super_res_type=2530
       and b.a_id=c.port_id and a.delete_state='0' and b.delete_state='0' and c.delete_state='0' and c.purpose='24110215'
/*union
select r2.parent_res_id eqp_id,sf_get_eqp_name(r2.parent_res_id) eqp_name,'' port_id,''term_no,''port_no from asn_link_route r1,asn_link_route r2
   where r1.parent_res_id=v_cntId and r1.delete_state='0'
   and r1.link_id=r2.link_id  and r2.delete_state='0' and r2.parent_res_type_id='2530' */

--新增18-1-19
union
SELECT g.cnt_box_id eqp_id ,g.cnt_box_name eqp_name ,c.term_id port_id,a.term_no,c.term_no port_no,'703' restype
 FROM rme_optic_term a,opt_logic_opt_pair b,rme_optic_term c,opt_connect_box g,opt_connect_box h
 where a.term_id=b.a_term and b.z_term=c.term_id and a.super_res_type=703 and c.super_res_type=703
       and c.super_res_id=g.cnt_box_id and a.super_res_id=v_cntId
       and a.delete_state='0' and b.delete_state='0' and c.delete_state='0' and g.delete_state='0'
;

--查询OBD下端口信息查询ONT信息（1）
cursor c_get_ont_by_eqpid1(v_obdId varchar2) is
select a.eqp_id z_eqp_id,sf_get_eqp_name(a.eqp_id) eqp_name,'2736' restype 
from rme_eqp a where a.parent_id=v_obdId and a.res_type_id =2736 
and not exists(
 select 1 from asn_link_route r1 ,srv_instance s1,srv_instance s2,asn_link_route r2
 where r1.parent_res_id = a.eqp_id and r1.delete_state='0'
 and s2.route_id=r2.link_id
 and r1.link_id=s1.route_id and s1.delete_state='0' and s1.dis_seq=s2.dis_seq and s2.delete_state='0' and s2.srv_id='12010002'
 and r2.parent_res_type_id= 704 and r2.delete_state='0'
);


--根据OBD查询下级光分箱(OBD-光交箱-光分箱)
cursor c_get_jnt_by_eqpid(v_obdId varchar2) is
select e.jnt_box_name,e.jnt_box_id,a.super_res_id,'704' restype from rme_port a,rme_optic_line b,rme_optic_term c,opt_logic_opt_pair d,opt_jnt_box e
 where a.port_id=b.a_id and b.z_id=c.term_id and c.term_id=d.z_term and a.super_res_type=2530 and c.super_res_type=703 and d.a_res_type_id=704
       and d.a_device_id=e.jnt_box_id and nvl(a.delete_state,'0')='0' and nvl(b.delete_state,'0')='0' and nvl(c.delete_state,'0')='0'
       and nvl(d.delete_state,'0')='0' and nvl(e.delete_state,'0')='0' and a.super_res_id=v_obdId and a.port_no not in('00')
union
select e.jnt_box_name,e.jnt_box_id,a.super_res_id,'704' restype from rme_port a,rme_optic_line b,rme_optic_term c,opt_logic_opt_pair d,opt_jnt_box e
 where a.port_id=b.z_id and b.a_id=c.term_id and c.term_id=d.z_term and a.super_res_type=2530 and c.super_res_type=703 and d.a_res_type_id=704
       and d.a_device_id=e.jnt_box_id and nvl(a.delete_state,'0')='0' and nvl(b.delete_state,'0')='0' and nvl(c.delete_state,'0')='0'
       and nvl(d.delete_state,'0')='0' and nvl(e.delete_state,'0')='0' and a.super_res_id=v_obdId and a.port_no not in('00')
union
select e.jnt_box_name,e.jnt_box_id,a.super_res_id,'704' restype from rme_port a,rme_optic_line b,rme_optic_term c,opt_logic_opt_pair d,opt_jnt_box e
 where a.port_id=b.a_id and b.z_id=c.term_id and c.term_id=d.a_term and a.super_res_type=2530 and c.super_res_type=703 and d.z_res_type_id=704
       and d.a_device_id=e.jnt_box_id and nvl(a.delete_state,'0')='0' and nvl(b.delete_state,'0')='0' and nvl(c.delete_state,'0')='0'
       and nvl(d.delete_state,'0')='0' and nvl(e.delete_state,'0')='0' and a.super_res_id=v_obdId and a.port_no not in('00')
union
select e.jnt_box_name,e.jnt_box_id,a.super_res_id,'704' restype from rme_port a,rme_optic_line b,rme_optic_term c,opt_logic_opt_pair d,opt_jnt_box e
 where a.port_id=b.z_id and b.a_id=c.term_id and c.term_id=d.a_term and a.super_res_type=2530 and c.super_res_type=703 and d.z_res_type_id=704
       and d.a_device_id=e.jnt_box_id and nvl(a.delete_state,'0')='0' and nvl(b.delete_state,'0')='0' and nvl(c.delete_state,'0')='0'
       and nvl(d.delete_state,'0')='0' and nvl(e.delete_state,'0')='0' and a.super_res_id=v_obdId and a.port_no not in('00')
/*
union
select r3.jnt_box_name,r3.jnt_box_id,r1.parent_res_id super_res_id from asn_link_route r1,asn_link_route r2,opt_jnt_box r3
   where r1.parent_res_id=v_obdId and r1.delete_state='0'
   and r1.link_id=r2.link_id  and r2.delete_state='0' and r2.parent_res_type_id='704' and r2.parent_res_id=r3.jnt_box_id and r3.delete_state='0'
*/
;

--根据光分查询ONT信息
cursor c_get_ont_by_jntid(v_jntid varchar2) is
select r1.parent_res_id,r2.parent_res_id eqp_id,sf_get_eqp_name(r2.parent_res_id) eqp_name,'2736' restype from asn_link_route r1,srv_instance i1,srv_instance i2, asn_link_route r2
   where r1.parent_res_id=v_jntid and r1.delete_state='0'
      and r2.delete_state='0' and r2.parent_res_type_id='2736'
   and r1.link_id=i1.route_id and i1.delete_state='0' and i1.dis_seq=i2.dis_seq and i2.delete_state='0'
   and i2.srv_id='12010003' and i2.route_id=r2.link_id ;

---查询OLT的统计信息
cursor c_get_olt_count_info_byid(v_eqpId varchar2) is
select olt_pon_cnt,opr_pon_cnt,(case when olt_pon_cnt>0 then round(opr_pon_cnt*100/olt_pon_cnt,2) else 0 end )||'%' buz_pob_cnt,room_name,eqp_no,eqp_name from (
select
 count(1) olt_pon_cnt,
 sum(case when t.opr_state_id in(170003,170002) then 1 else 0 end) opr_pon_cnt,
-- (case when olt_pon_cnt>0 then opr_pon_cnt/olt_pon_cnt else 0 end ) buz_pob_cnt ,
 (select m.china_name from spc_room m  where m.room_id=p.posit_id  ) room_name,
 eqp_no,eqp_name
from rme_port t,rme_eqp p where t.super_res_id = p.eqp_id and t.delete_state='0' and p.eqp_id=v_eqpId group by p.eqp_id,eqp_no,eqp_name,p.posit_id
)
;
---查询OLT的详细信息
cursor c_get_olt_detail_info_byid(v_eqpId varchar2) is
select b.port_no  ,
       i.vlan_num kd_vlan,
       i.vlan_num itv_vlan,
       i.vlan_num zx_vlan,
       n.vlan_num yy_vlan,
       l.rack_no  odf_no,
       k.term_no  term_no
  from rme_eqp a
  left join rme_port b
    on a.eqp_id = b.super_res_id  and b.delete_state = 0
  left join ipaddr_bind c 
    on b.port_id = c.res_id and c.delete_state = 0
  left join dat_vlan i
    on b.vlan = i.vlan_id
   and b.svlan_id = i.vlan_id
   and b.vlan_out = i.vlan_id and i.delete_state = 0
  left join ipaddr_ipsubnet d
    on c.ip_segm_id = d.ip_segm_id and d.delete_state = 0
  left join dat_vlan n
    on d.vlan = n.vlan_id  and n.delete_state = 0
  left join rme_optic_line e
    on b.port_id = e.a_id
   and e.a_type_id = 2531 and e.delete_state = 0
  left join rme_rack l
    on e.z_eqp_id = l.rack_id and l.delete_state = 0
  left join rme_optic_term k 
    on e.z_id = k.term_id  and k.delete_state = 0
 where b.res_type_id = 2531
   and a.res_type_id = 2510
   and a.delete_state = 0
   and a.eqp_id = v_eqpId
;
--查询ODF的详细信息 
CURSOR C_GET_ODF_DETAIL_INFO_BYID(V_ODFID VARCHAR2) IS
SELECT A.RACK_NO,T1.TERM_NO,T1.POSITION,D.CNT_BOX_NAME,T.TERM_NO GJ_TERM_NO,'' OBD_NO
     FROM RME_RACK A,RME_OPTIC_TERM T1, OPT_LOGIC_OPT_PAIR C,OPT_CONNECT_BOX D,RME_OPTIC_TERM T
     WHERE A.RACK_ID = V_ODFID  AND T1.TERM_ID=C.Z_TERM  AND C.A_TERM=T.TERM_ID AND T.SUPER_RES_ID=D.CNT_BOX_ID
     AND T1.SUPER_RES_ID= A.RACK_ID   AND C.DELETE_STATE='0' AND T1.DELETE_STATE='0' AND T.DELETE_STATE='0'
 UNION
  SELECT A.RACK_NO,T1.TERM_NO,T1.POSITION,D.CNT_BOX_NAME,T.TERM_NO GJ_TERM_NO,'' OBD_NO
     FROM RME_RACK A,RME_OPTIC_TERM T1, OPT_LOGIC_OPT_PAIR C,OPT_CONNECT_BOX D,RME_OPTIC_TERM T
     WHERE A.RACK_ID = V_ODFID  AND T1.TERM_ID=C.A_TERM  AND C.Z_TERM=T.TERM_ID AND T.SUPER_RES_ID=D.CNT_BOX_ID
     AND T1.SUPER_RES_ID= A.RACK_ID   AND C.DELETE_STATE='0' AND T1.DELETE_STATE='0' AND T.DELETE_STATE='0'
   ;
 
--查询光交的详细信息 
CURSOR C_GET_CNT_DETAIL_INFO_BYID(V_CNTID VARCHAR2) IS
   SELECT 
      T.TERM_ID,
      T.TERM_NO ,
      D.CNT_BOX_NO ,
      (
       SELECT  R1.RACK_NO||'[&]'||T1.TERM_NO 
       FROM RME_RACK R1,RME_OPTIC_TERM T1, OPT_LOGIC_OPT_PAIR C1
       WHERE ((C1.A_TERM = T.TERM_ID AND C1.Z_TERM =T1.TERM_ID  AND C1.Z_RES_TYPE_ID = 302 ) OR 
             (C1.Z_TERM = T.TERM_ID AND C1.A_TERM =T1.TERM_ID  AND C1.A_RES_TYPE_ID = 302) )
        AND C1.DELETE_STATE ='0' 
        AND T1.DELETE_STATE ='0' AND T1.SUPER_RES_ID = R1.RACK_ID  AND ROWNUM =1 
      ) RACK_TERM,
      (
        SELECT  (SELECT CN1.CNT_BOX_NAME FROM OPT_CONNECT_BOX CN1 WHERE CN1.CNT_BOX_ID=T1.SUPER_RES_ID  )||'[&]'||T1.TERM_NO 
       FROM RME_OPTIC_TERM T1, OPT_LOGIC_OPT_PAIR C1
       WHERE ((C1.A_TERM = T.TERM_ID AND C1.Z_TERM =T1.TERM_ID AND C1.Z_RES_TYPE_ID = 703 ) OR 
             (C1.Z_TERM = T.TERM_ID AND C1.A_TERM =T1.TERM_ID  AND C1.A_RES_TYPE_ID = 703 ) )
        AND C1.DELETE_STATE ='0' 
        AND T1.DELETE_STATE ='0'  AND ROWNUM =1 
      ) SUB_TERM,
      (
        SELECT 
        (SELECT E1.EQP_NO FROM RME_EQP E1 WHERE E1.EQP_ID=T1.SUPER_RES_ID  )||'[&]'||T1.PORT_NO 
        FROM RME_PORT T1 ,RME_OPTIC_LINE L1 
        WHERE ((T1.PORT_ID =L1.A_ID AND L1.Z_ID =T.TERM_ID) OR (T1.PORT_ID =L1.Z_ID AND L1.A_ID =T.TERM_ID))
              AND T1.DELETE_STATE='0' AND L1.DELETE_STATE='0'
      ) SUB_OBD 
     
     FROM  OPT_CONNECT_BOX D ,RME_OPTIC_TERM T 
     
     WHERE T.SUPER_RES_ID =D.CNT_BOX_ID AND T.DELETE_STATE ='0' AND D.CNT_BOX_ID =V_CNTID
     ;      

---查询ODF的统计信息
cursor c_get_odf_count_info_byid(v_eqpId varchar2) is
  select odf_term_cnt,opr_term_cnt,(case when odf_term_cnt>0 then round(opr_term_cnt*100/odf_term_cnt,2) else 0 end )||'%' buz_pob_cnt,room_name,rack_no,rack_name from (
 select
 count(1) odf_term_cnt,
 sum(case when t.opr_state_id in(170003,170002) then 1 else 0 end) opr_term_cnt,
-- (case when olt_pon_cnt>0 then opr_pon_cnt/olt_pon_cnt else 0 end ) buz_pob_cnt ,
 (select m.china_name from spc_room m  where m.room_id=p.posit_id  ) room_name,
 rack_no,rack_name
from rme_optic_term t,rme_rack p where t.super_res_id = p.rack_id and t.delete_state='0' and p.rack_id=v_eqpId group by p.rack_id,rack_no,rack_name,p.posit_id
)
;

--查询光交的统计信息
cursor c_get_cnt_info_byId(v_eqpId varchar2) is
select t.*,l.* ,round((all_term-free_term)*100/all_term,2)||'%' use_percent,n.region_name,(all_term-free_term) use_term from
(select a.cnt_box_no,a.cnt_box_name,a.region_id from opt_connect_box a where a.cnt_box_id=v_eqpId and a.delete_state='0') t,
(select count(1) all_term from rme_optic_term b where b.super_res_id=v_eqpId and b.delete_state='0') l,  --端子总数
(select count(1) free_term from rme_optic_term c where c.super_res_id=v_eqpId and c.opr_state_id='170001' and c.delete_state='0') m,
(select d.region_name,d.region_id from spc_region d where d.delete_state='0') n
where t.region_id=n.region_id
;

--查询OBD统计信息
cursor c_get_obd_info_byId(v_eqpId varchar2) is
select l.*,m.*,d.region_name,n.*,(ALL_PORT-FREE_PORT) use_port,round((ALL_PORT-FREE_PORT)*100/ALL_pORT,2)||'%' use_percent from
(select count(1) all_port from
(select * from rme_port a where a.super_res_id=v_eqpId and a.delete_state='0'and a.port_no not in('00'))) l, -- 总数
(select count(1) free_port from
(select * from rme_port b where b.super_res_id=v_eqpId and b.delete_state='0'and b.opr_state_id='170001' and b.port_no not in('00'))) m, --空闲数
 (select c.eqp_no,c.eqp_name,c.address,c.region_id from rme_eqp c where c.eqp_id=v_eqpId and c.delete_state='0') n,
(select region_name,region_id from spc_region where delete_state='0' )d
where n.region_id=d.region_id
;

--查询OBD的详细信息
CURSOR C_GET_OBD_DETAIL_INFO_BYID(V_EQPID VARCHAR2) IS
SELECT B.PORT_NAME    OBD_PORT_NO,--OBD端子编码,
       SF_GET_DESC_CHINA(B.OPR_STATE_ID)  OPR_STATE,
       G.JNT_BOX_NAME ,--光分编码,
       F.TERM_NO      ,--光分端子编码,
       O.EQP_NO       ,--ONT设备编码,
       I.PORT_NO      ,--ONT端口,
       YW.TELE_NO     ,--业务号码,
       YW.PROD_NAME  ,-- 业务类型,
       V1.VLAN_NUM    SVLAN,
       V2.VLAN_NUM    CVLAN,
       B1.PORT_NO      PON,
       A1.PARAM_DESC  SPEED,--账号,
       A2.PARAM_DESC  ACCOUNT,--速率,
       YW.ADDRESS ,--装机地址,
       '' LAST_TIME,--最近登录时间,
       W.LOID SN,--光猫串码
       YW.FINISH_TIME,
       CU.CUST_NAME
  FROM RME_EQP A
  LEFT JOIN RME_PORT B
    ON A.EQP_ID = B.SUPER_RES_ID AND B.DELETE_STATE = '0'
  LEFT JOIN RME_OPTIC_LINE C
    ON B.PORT_ID = C.A_ID AND C.DELETE_STATE = '0'
   AND C.A_TYPE_ID = 2531
  LEFT JOIN RME_OPTIC_TERM D
    ON D.TERM_ID = A.EQP_ID AND D.DELETE_STATE = '0'
  LEFT JOIN OPT_LOGIC_OPT_PAIR E
    ON D.TERM_ID = E.A_TERM AND E.DELETE_STATE = '0'
  LEFT JOIN RME_OPTIC_TERM F
    ON E.Z_TERM = F.TERM_ID AND  F.DELETE_STATE = '0'
  LEFT JOIN OPT_JNT_BOX G
    ON F.SUPER_RES_ID = G.JNT_BOX_ID AND G.DELETE_STATE = '0'
  LEFT JOIN ASN_LINK_ROUTE LY
    ON B.PORT_ID = LY.RES_ID AND LY.DELETE_STATE = '0'
  LEFT JOIN SRV_INSTANCE SL
    ON LY.LINK_ID = SL.ROUTE_ID AND SL.DELETE_STATE = '0'
  LEFT JOIN SRV_BUSINESS YW  ON SL.DIS_SEQ = YW.DIS_SEQ AND YW.DELETE_STATE = '0'
  LEFT JOIN SRV_INSTANCE SL1  ON SL1.DIS_SEQ = YW.DIS_SEQ AND SL1.DELETE_STATE = '0' AND SL1.SRV_ID ='12010003' 
  LEFT JOIN ASN_LINK_ROUTE LY1 ON SL1.ROUTE_ID=LY1.LINK_ID AND LY1.DELETE_STATE = '0' 
  LEFT JOIN PUB_CUST CU ON CU.CUST_ID = YW.CUST_ID AND CU.DELETE_STATE = '0'
  LEFT JOIN RME_PORT I ON LY1.RES_ID = I.PORT_ID AND I.DELETE_STATE='0' 
  LEFT JOIN RME_EQP O ON I.SUPER_RES_ID = O.EQP_ID  AND O.DELETE_STATE = '0' AND O.RES_TYPE_ID = 2736
  LEFT JOIN RME_OUT_EQP W ON O.EQP_ID = W.EQP_ID AND W.DELETE_STATE = '0'
  LEFT JOIN SRV_ORDER_DETAIL A1 ON YW.ORDER_ID = A1.ORDER_ID AND A1.DELETE_STATE = '0' AND A1.PARAM_DESC = 'port_rate'
  LEFT JOIN SRV_ORDER_DETAIL A2  ON A1.ORDER_ID = A2.ORDER_ID AND  A2.DELETE_STATE = '0' AND A2.PARAM_DESC = 'user_name'
  LEFT JOIN SRV_INSTANCE SL2  ON SL2.DIS_SEQ = YW.DIS_SEQ AND SL2.DELETE_STATE = '0' AND SL2.SRV_ID ='12010032' 
  LEFT JOIN ASN_LINK_ROUTE LY2 ON SL2.ROUTE_ID=LY2.LINK_ID AND LY2.DELETE_STATE = '0' 
  LEFT JOIN DAT_VLAN V1 ON LY2.PARENT_RES_ID = V1.VLAN_ID AND V1.DELETE_STATE = '0'
  LEFT JOIN DAT_VLAN V2 ON LY2.RES_ID = V2.VLAN_ID AND V2.DELETE_STATE = '0'
  LEFT JOIN RME_PORT B1 ON A.RACK_ID=B1.PORT_ID AND B1.DELETE_STATE = '0'
  WHERE A.RES_TYPE_ID in(2530,2736) AND A.EQP_ID = V_EQPID  ;

--查询ONT统计信息
cursor c_get_ont_info_byId(v_eqpId varchar2) is
select l.*,m.*,n.*,(all_port-free_port) use_port,round((all_port-free_port)*100/all_port,2)||'%' use_percent from
(select a.address,a.eqp_no,a.create_date,sf_get_eqp_model(a.eqp_model_id) eqp_model,r.loid from rme_eqp a,rme_out_eqp r where a.eqp_id=v_eqpId and a.res_type_id=2736 and a.delete_state='0' and a.eqp_id=r.eqp_id)l,
(select count(1) all_port from rme_port b where b.super_res_id=v_eqpId and b.delete_state='0' and b.super_res_type=2736 and b.port_no not in('00'))m, --总数
(select count(1) free_port from rme_port c where c.super_res_id=v_eqpId and c.delete_state='0' and c.super_res_type=2736 and c.opr_state_id='170001')n  --空闲数
;

--查询根节点名称
cursor c_get_res_name_byId(v_resId varchar2) is
  select sf_get_res_name(v_resId) resname from dual;

--查询ONT的上级OBD光分等信息-跳接信息
CURSOR C_GET_ONT_SUPER_INFO_BYID(V_EQPID VARCHAR2) IS
select  r1.link_id,
  (select jnt.jnt_box_id from asn_link_route r2,rme_optic_term t,opt_jnt_box jnt
    where r2.delete_state='0' and r2.link_id=r1.link_id and r2.parent_res_type_id='704'
     and r2.res_id=t.term_id and jnt.jnt_box_id=t.super_res_id and rownum =1
  ) jnt_box_id,
  (select jnt.jnt_box_no from asn_link_route r2,rme_optic_term t,opt_jnt_box jnt
    where r2.delete_state='0' and r2.link_id=r1.link_id and r2.parent_res_type_id='704'
     and r2.res_id=t.term_id and jnt.jnt_box_id=t.super_res_id and rownum =1
  ) jnt_box_no,
  (select cnt.cnt_box_id from asn_link_route r2,rme_optic_term t,opt_connect_box cnt
    where r2.delete_state='0' and r2.link_id=r1.link_id and r2.parent_res_type_id='704'
     and r2.res_id=t.term_id and cnt.cnt_box_id=t.super_res_id and rownum =1
  ) cnt_box_id,
  (select cnt.cnt_box_no from asn_link_route r2,rme_optic_term t,opt_connect_box cnt
    where r2.delete_state='0' and r2.link_id=r1.link_id and r2.parent_res_type_id='704'
     and r2.res_id=t.term_id and cnt.cnt_box_id=t.super_res_id and rownum =1
  ) cnt_box_no,
  obd.eqp_id obd_id,
  obd.eqp_no obd_no,
  obd.parent_id parent_obd_id,
  obd.business_grade obd_business_grade,
  ont.eqp_id,ont.eqp_no
  from 
  rme_eqp ont ,asn_link_route r,srv_instance i,srv_instance i1 ,asn_link_route r1,rme_eqp obd 
  where  ont.eqp_id ='000127360040000003191012' 
  and r.delete_state(+)='0' and ont.eqp_id=r.parent_res_id(+)
  and i.delete_state(+)='0' and r.link_id=i.route_id(+)
  and i1.delete_state(+)='0' and i.dis_seq=i1.dis_seq(+) and i1.srv_id(+)='12010002'
  and r1.delete_state(+)='0' and i1.route_id=r1.link_id(+)
  and ont.parent_id=obd.eqp_id(+)
;
--查询一级OBD的上级连接-跳接信息
CURSOR C_GET_OBD_SUPER_INFO_BYID(V_EQPID VARCHAR2) IS
select t.port_id,t.port_no,obd.eqp_id obd_eqp_id,obd.eqp_no obd_eqp_no,te.term_id,te.term_no,te.super_res_id cnt_box_id,cnt.cnt_box_no,pon.port_no pon,olt.eqp_id olt_eqp_id,olt.eqp_no olt_eqp_no
 from rme_optic_line l,rme_port t ,rme_optic_term te,opt_connect_box cnt,rme_eqp obd,rme_port pon,rme_eqp olt
where t.super_res_id =V_EQPID   and t.super_res_id=obd.eqp_id and obd.rack_id=pon.port_id and pon.super_res_id = olt.eqp_id
and t.port_no in('00','0')  and te.super_res_id=cnt.cnt_box_id
and l.delete_state='0' and t.delete_state='0' and te.delete_state='0'
and t.port_id=l.a_id and l.z_id=te.term_id 
union
select t.port_id,t.port_no,obd.eqp_id obd_eqp_id,obd.eqp_no obd_eqp_no,te.term_id,te.term_no,te.super_res_id cnt_box_id,cnt.cnt_box_no,pon.port_no pon,olt.eqp_id olt_eqp_id,olt.eqp_no olt_eqp_no
 from rme_optic_line l,rme_port t ,rme_optic_term te,opt_connect_box cnt,rme_eqp obd,rme_port pon,rme_eqp olt
where t.super_res_id =V_EQPID and t.super_res_id=obd.eqp_id and obd.rack_id=pon.port_id and pon.super_res_id = olt.eqp_id
and t.port_no in('00','0')  and te.super_res_id=cnt.cnt_box_id
and l.delete_state='0' and t.delete_state='0' and te.delete_state='0'
and t.port_id=l.z_id and l.a_id=te.term_id  ;

--查询设施的局纤上级连接信息
CURSOR C_GET_ENT_SUPER_INFO_BYID(V_termID VARCHAR2) IS
select te.term_id,te.term_no,703 res_type_id,cnt.cnt_box_id,cnt.cnt_box_no 
from opt_logic_opt_pair a ,rme_optic_term te,opt_connect_box cnt
where a.a_term=V_termID and a.z_term = te.term_id 
  and te.super_res_id=cnt.cnt_box_id and a.delete_state='0' and te.delete_state='0' and cnt.delete_state='0'
union
select te.term_id,te.term_no,703 res_type_id,cnt.cnt_box_id,cnt.cnt_box_no 
from opt_logic_opt_pair a ,rme_optic_term te,opt_connect_box cnt
where a.z_term=V_termID and a.a_term = te.term_id 
  and te.super_res_id=cnt.cnt_box_id and a.delete_state='0' and te.delete_state='0' and cnt.delete_state='0'
 
union
select te.term_id,te.term_no,302 res_type_id,rack.rack_id,rack.rack_no
from opt_logic_opt_pair a ,rme_optic_term te,rme_rack rack
where a.a_term=V_termID and a.z_term = te.term_id 
  and te.super_res_id=rack.rack_id and a.delete_state='0' and te.delete_state='0' and rack.delete_state='0'
union
select te.term_id,te.term_no,302 res_type_id,rack.rack_id,rack.rack_no
from opt_logic_opt_pair a ,rme_optic_term te,rme_rack rack
where a.z_term=V_termID and a.a_term = te.term_id 
  and te.super_res_id=rack.rack_id and a.delete_state='0' and te.delete_state='0' and rack.delete_state='0'
  ;
---查询端子跳接信息
CURSOR C_GET_LINE_INFO_BYID(V_termID VARCHAR2) IS
  select t.z_id term_id from rme_optic_line t where t.a_id = V_termID and t.delete_state='0' 
  union
  select t.a_id term_id from rme_optic_line t where t.z_id = V_termID and t.delete_state='0' 
;

BEGIN
  v_resId  :=  substr(inmethonId,2,24) ;
  v_res_type_id :=  substr(v_resId,5,4) ;
  v_has_cnt:=0;
   ---intype 1 查询当前资源名称
   ---intype 2 查询下级资源
   ---intype 3 查询资源属性
   ---intype 4 查询资源业务信息
   if intype = 3 then
    v_return := '[';
    if v_res_type_id = 2510 then
     
     for c_h in c_get_olt_count_info_byid(v_resId) loop
        if c_h.eqp_no is not null then
           v_return :=concat(v_return ,'{"ATTR_NAME":"设备编码","ATTR_VALUE":"'||c_h.eqp_no||'"},');
           v_return :=concat(v_return ,'{"ATTR_NAME":"设备名称","ATTR_VALUE":"'||c_h.eqp_name||'"},');
           v_return :=concat(v_return ,'{"ATTR_NAME":"PON口数","ATTR_VALUE":"'||c_h.olt_pon_cnt||'"},');
           v_return :=concat(v_return ,'{"ATTR_NAME":"PON口占用数","ATTR_VALUE":"'||c_h.opr_pon_cnt||'"},');
           v_return :=concat(v_return ,'{"ATTR_NAME":"利用率","ATTR_VALUE":"'||c_h.buz_pob_cnt||'"},');
           v_return :=concat(v_return ,'{"ATTR_NAME":"所属机房","ATTR_VALUE":"'||c_h.room_name||'"},');
        end if;
       end loop;
     elsif v_res_type_id = 302 then
       for c_h in c_get_odf_count_info_byid(v_resId) loop
        if c_h.rack_no is not null then
          v_return :=concat(v_return ,'{"ATTR_NAME":"设备编码","ATTR_VALUE":"'||c_h.rack_no||'"},');
           v_return :=concat(v_return ,'{"ATTR_NAME":"设备名称","ATTR_VALUE":"'||c_h.rack_name||'"},');
           v_return :=concat(v_return ,'{"ATTR_NAME":"ODF端子数","ATTR_VALUE":"'||c_h.odf_term_cnt||'"},');
           v_return :=concat(v_return ,'{"ATTR_NAME":"PON口占用数","ATTR_VALUE":"'||c_h.opr_term_cnt||'"},');
           v_return :=concat(v_return ,'{"ATTR_NAME":"ODF端子占用数","ATTR_VALUE":"'||c_h.buz_pob_cnt||'"},');
           v_return :=concat(v_return ,'{"ATTR_NAME":"利用率","ATTR_VALUE":"'||c_h.buz_pob_cnt||'"},');
           v_return :=concat(v_return ,'{"ATTR_NAME":"所属机房","ATTR_VALUE":"'||c_h.room_name||'"},');
         end if;
       end loop;
       elsif v_res_type_id = 703 then
         for c_h in c_get_cnt_info_byId(v_resId) loop
           if c_h.cnt_box_no is not null then
             v_return :=concat(v_return ,'{"ATTR_NAME":"设备编码","ATTR_VALUE":"'||c_h.cnt_box_no||'"},');
             v_return :=concat(v_return ,'{"ATTR_NAME":"设备名称","ATTR_VALUE":"'||c_h.cnt_box_name||'"},');
             v_return :=concat(v_return ,'{"ATTR_NAME":"光交端子数","ATTR_VALUE":"'||c_h.all_term||'"},');
             v_return :=concat(v_return ,'{"ATTR_NAME":"光交端子占用数","ATTR_VALUE":"'||c_h.use_term||'"},');
             v_return :=concat(v_return ,'{"ATTR_NAME":"利用率","ATTR_VALUE":"'||c_h.use_percent||'"},');
             v_return :=concat(v_return ,'{"ATTR_NAME":"所属区域","ATTR_VALUE":"'||c_h.region_name||'"},');
        end if;
       end loop;
       elsif v_res_type_id = 2530 then
       for c_h in c_get_obd_info_byId(v_resId) loop
         if c_h.eqp_no is not null then
            v_return :=concat(v_return ,'{"ATTR_NAME":"设备编码","ATTR_VALUE":"'||c_h.eqp_no||'"},');
             v_return :=concat(v_return ,'{"ATTR_NAME":"设备名称","ATTR_VALUE":"'||c_h.eqp_name||'"},');
             v_return :=concat(v_return ,'{"ATTR_NAME":"OBD端口数","ATTR_VALUE":"'||c_h.all_port||'"},');
             v_return :=concat(v_return ,'{"ATTR_NAME":"OBD端口占用数","ATTR_VALUE":"'||c_h.use_port||'"},');
             v_return :=concat(v_return ,'{"ATTR_NAME":"利用率","ATTR_VALUE":"'||c_h.use_percent||'"},');
             v_return :=concat(v_return ,'{"ATTR_NAME":"所属区域","ATTR_VALUE":"'||c_h.region_name||'"},');
             v_return :=concat(v_return ,'{"ATTR_NAME":"安装地址","ATTR_VALUE":"'||c_h.address||'"},');
          end if;
       end loop;
       elsif v_res_type_id=2736 then
        for c_h in c_get_ont_info_byId(v_resId) loop
          if c_h.eqp_no is not null then
            v_return :=concat(v_return ,'{"ATTR_NAME":"设备编码","ATTR_VALUE":"'||c_h.eqp_no||'"},');
             v_return :=concat(v_return ,'{"ATTR_NAME":"安装地址","ATTR_VALUE":"'||c_h.address||'"},');
             v_return :=concat(v_return ,'{"ATTR_NAME":"ONT端口数","ATTR_VALUE":"'||c_h.all_port||'"},');
             v_return :=concat(v_return ,'{"ATTR_NAME":"ONT端口占用数","ATTR_VALUE":"'||c_h.use_port||'"},');
             v_return :=concat(v_return ,'{"ATTR_NAME":"利用率","ATTR_VALUE":"'||c_h.use_percent||'"},');
             v_return :=concat(v_return ,'{"ATTR_NAME":"SN号","ATTR_VALUE":"'||c_h.loid||'"},');
             v_return :=concat(v_return ,'{"ATTR_NAME":"开通时间","ATTR_VALUE":"'||c_h.create_date||'"},');
             v_return :=concat(v_return ,'{"ATTR_NAME":"设备型号","ATTR_VALUE":"'||c_h.eqp_model||'"},');
             v_return :=concat(v_return ,'{"ATTR_NAME":"设备属性","ATTR_VALUE":"自建"},');
             
            end if;
         end loop;
     end if;
    v_return := rtrim(v_return ,',');
    v_return := concat(v_return ,']');
    return v_return;
  end if;

   if intype = 4 then
     
     v_r_heard:='[';
     v_r_body:='[';
    if v_res_type_id = 2510 then
      v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"PORT_NO","label":"PON口编码", "width":"100"},');
      v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"KD_VLAN","label":"宽带SVLAN", "width":"100"},');
      v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"ITV_VLAN","label":"IPTV-SVLAN", "width":"100"},');
      v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"ZX_VLAN","label":"专线宽带SVLAN", "width":"100"},');
      v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"YY_VLAN","label":"语音SVLAN", "width":"100"},');
      v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"ODF_NO","label":"下联ODF设备编码", "width":"100"},');
      v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"TERM_NO","label":"下联ODF端子编码", "width":"100"},');
      
       for c_h in c_get_olt_detail_info_byid(v_resId) loop
        if c_h.port_no is not null then
          v_r_body :=concat(v_r_body ,'{"PORT_NO":"'||c_h.port_no||'","KD_VLAN":"'||c_h.kd_vlan||'","ITV_VLAN":"'||c_h.itv_vlan||'","ZX_VLAN":"'||c_h.zx_vlan||'","ODF_NO":"'||c_h.odf_no||'","TERM_NO":"'||c_h.term_no||'"},');
        end if;
       end loop;
     elsif v_res_type_id = 302 then
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"PORT_NO","label":"端子编码", "width":"100"},');
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"RACK_NAME","label":"设备编码", "width":"100"},');
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"POSITHION","label":"端子序号", "width":"100"},');
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"SUB_CNT","label":"下联光交", "width":"100"},');
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"SUB_CNT_TERM","label":"下联光交端子", "width":"100"},');
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"OBD_NO","label":"OBD", "width":"100"},');
          
       for c_h in C_GET_ODF_DETAIL_INFO_BYID(v_resId) loop
        if c_h.TERM_NO is not null then
          v_r_body :=concat(v_r_body ,'{"PORT_NO":"'||c_h.TERM_NO||'","RACK_NAME":"'||c_h.RACK_NO||'","POSITHION":"'||c_h.POSITION||'","SUB_CNT":"'||c_h.CNT_BOX_NAME||'","SUB_CNT_TERM":"'||c_h.GJ_TERM_NO||'","OBD_NO":"'||c_h.OBD_NO||'"},');
        end if;
       end loop;
       elsif v_res_type_id = 703 then
         
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"TERM_NO","label":"端子编码", "width":"100"},');
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"CNT_BOX_NAME","label":"设备编码", "width":"100"},');
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"SUPER_EQP_NO","label":"上联设备编码", "width":"100"},');
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"SUPER_TERM_NO","label":"上联设备端子", "width":"100"},');
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"SUB_CNT","label":"下联设备(非OBD)", "width":"100"},');
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"SUB_CNT_TERM","label":"下联设备端子(非OBD)", "width":"100"},');
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"OBD_NO","label":"下联OBD", "width":"100"},');
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"OBD_TERM_NO","label":"下联OBD端口", "width":"100"},');
          
          for c_h in C_GET_CNT_DETAIL_INFO_BYID(v_resId) loop
           if c_h.term_id is not null then
              v_r_body :=concat(v_r_body ,'{"TERM_NO":"'||c_h.TERM_NO);
              v_r_body :=concat(v_r_body ,'","CNT_BOX_NAME":"'||c_h.cnt_box_no);
              IF c_h.rack_term is not null and instr(c_h.rack_term,'[&]')>1 then
                 v_r_body :=concat(v_r_body ,'","SUPER_EQP_NO":"'||substr(c_h.rack_term,1,instr(c_h.rack_term,'[&]')-1));
                 v_r_body :=concat(v_r_body ,'","SUPER_TERM_NO":"'||substr(c_h.rack_term,instr(c_h.rack_term,'[&]')+3,length(c_h.rack_term)-instr(c_h.rack_term,'[&]')-2));
              else
                  v_r_body :=concat(v_r_body ,'","SUPER_EQP_NO":"');
                  v_r_body :=concat(v_r_body ,'","SUPER_TERM_NO":"'||c_h.rack_term);
              end if;
              IF c_h.sub_term is not null and instr(c_h.sub_term,'[&]')>1 then
                 v_r_body :=concat(v_r_body ,'","SUB_CNT":"'||substr(c_h.sub_term,1,instr(c_h.sub_term,'[&]')-1));
                 v_r_body :=concat(v_r_body ,'","SUB_CNT_TERM":"'||substr(c_h.sub_term,instr(c_h.sub_term,'[&]')+3,length(c_h.sub_term)-instr(c_h.sub_term,'[&]')-2));
              else
                  v_r_body :=concat(v_r_body ,'","SUB_CNT":"');
                  v_r_body :=concat(v_r_body ,'","SUB_CNT_TERM":"'||c_h.sub_term);
              end if;
              IF c_h.sub_obd is not null and instr(c_h.sub_obd,'[&]')>1 then
                 v_r_body :=concat(v_r_body ,'","OBD_NO":"'||substr(c_h.sub_obd,1,instr(c_h.sub_obd,'[&]')-1));
                 v_r_body :=concat(v_r_body ,'","OBD_TERM_NO":"'||substr(c_h.sub_obd,instr(c_h.sub_obd,'[&]')+3,length(c_h.sub_obd)-instr(c_h.sub_obd,'[&]')-2));
              else
                  v_r_body :=concat(v_r_body ,'","OBD_NO":"');
                  v_r_body :=concat(v_r_body ,'","OBD_TERM_NO":"'||c_h.sub_obd);
              end if;
              v_r_body :=concat(v_r_body ,'"},');
           end if;
          end loop;
       
       elsif v_res_type_id in( 2530 , 2736) then
         
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"OBD_PORT_NO","label":"端子编码", "width":"100"},');
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"OPR_STATE","label":"业务状态", "width":"100"},');
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"ONT_EQP_NO","label":"ONT设备编码", "width":"100"},');
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"ONT_PORT_NO","label":"ONT设备端口", "width":"100"},');
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"ONT_SN","label":"ONT设备SN", "width":"100"},');
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"TELE_NO","label":"业务号码", "width":"100"},');
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"ACCOUNT","label":"宽带账号", "width":"100"},');
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"PROD_TYPE","label":"业务类型", "width":"100"},');
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"SVLAN","label":"SVLAN", "width":"100"},');
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"CVLAN","label":"CVLAN", "width":"100"},');
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"PON_NO","label":"PON口", "width":"100"},');
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"FINISH_TIME","label":"竣工时间", "width":"100"},');
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"SPEED","label":"宽带速率", "width":"100"},');
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"USER_NAME","label":"用户名称", "width":"100"},');
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"ADDRESS","label":"装机地址", "width":"100"},');
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"LAST_TIME","label":"最近登陆时间", "width":"100"},');
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"ONT_C_SN","label":"串码", "width":"100"},');
          
        for c_h in C_GET_OBD_DETAIL_INFO_BYID(v_resId) loop
         if c_h.obd_port_no is not null then
              v_r_body :=concat(v_r_body ,'{"OBD_PORT_NO":"'||c_h.obd_port_no);
              v_r_body :=concat(v_r_body ,'","OPR_STATE":"'||c_h.OPR_STATE);
              if c_h.eqp_no is null and v_res_type_id = 2736 then
                v_r_body :=concat(v_r_body ,'","ONT_EQP_NO":"'||sf_get_res_name(v_resId));
                v_r_body :=concat(v_r_body ,'","ONT_PORT_NO":"'||c_h.obd_port_no);
              else 
                v_r_body :=concat(v_r_body ,'","ONT_EQP_NO":"'||c_h.eqp_no);
                v_r_body :=concat(v_r_body ,'","ONT_PORT_NO":"'||c_h.Port_No);
              end if;
              v_r_body :=concat(v_r_body ,'","ONT_SN":"'||c_h.sn);
              v_r_body :=concat(v_r_body ,'","TELE_NO":"'||c_h.tele_no);
              v_r_body :=concat(v_r_body ,'","ACCOUNT":"'||c_h.Account);
              v_r_body :=concat(v_r_body ,'","PROD_TYPE":"'||c_h.Prod_Name);
              v_r_body :=concat(v_r_body ,'","SVLAN":"'||c_h.Svlan);
              v_r_body :=concat(v_r_body ,'","CVLAN":"'||c_h.Cvlan);
              v_r_body :=concat(v_r_body ,'","PON_NO":"'||c_h.pon);
              v_r_body :=concat(v_r_body ,'","FINISH_TIME":"'||c_h.FINISH_TIME);
              v_r_body :=concat(v_r_body ,'","SPEED":"'||c_h.Speed);
              v_r_body :=concat(v_r_body ,'","USER_NAME":"'||c_h.CUST_NAME);
              v_r_body :=concat(v_r_body ,'","ADDRESS":"'||c_h.Address);
              v_r_body :=concat(v_r_body ,'","LAST_TIME":"'||c_h.Last_Time);
              v_r_body :=concat(v_r_body ,'","ONT_C_SN":"'||c_h.Sn);
              v_r_body :=concat(v_r_body ,'"},');
           end if;
        end loop;
     end if;
      v_r_heard := rtrim(v_r_heard ,',');
      v_r_body := rtrim(v_r_body ,',');
      v_r_heard := concat(v_r_heard ,']');
      v_r_body := concat(v_r_body ,']');
      v_return := '{';
      v_return := concat(v_return ,'"heard":');
      v_return := concat(v_return ,v_r_heard);
      v_return := concat(v_return ,',');
      v_return := concat(v_return ,'"body":');
      v_return := concat(v_return ,v_r_body);
      v_return := concat(v_return ,'}');
      
      --v_v200 :=  v_return;
    return v_return;
  end if;
  
  if intype = 5 then
     
     v_r_heard:='[';
     v_r_body:='[';
    if v_res_type_id in(2530) then
        v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"OBD_PORT_NO","label":"OBD端子", "width":"100"},');
        for c_h_obd in C_GET_OBD_SUPER_INFO_BYID(v_resId) loop
           v_r_body :=concat(v_r_body ,'{"OBD_PORT_NO":"'||c_h_obd.port_no);
           if c_h_obd.term_id is not null then
              v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"CNT_EQP_NO","label":"光交设备", "width":"200"},');
              v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"CNT_TERM_NO","label":"光交端子", "width":"100"},');
              v_r_body :=concat(v_r_body ,'","CNT_EQP_NO":"'||c_h_obd.cnt_box_no);
              v_r_body :=concat(v_r_body ,'","CNT_TERM_NO":"'||c_h_obd.term_no);
              for c_h_cnt in C_GET_ENT_SUPER_INFO_BYID(c_h_obd.term_id) loop
                  if c_h_cnt.res_type_id = 302 then
                    v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"RACK_EQP_NO","label":"ODF设备", "width":"200"},');
                    v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"RACK_TERM_NO","label":"ODF端子", "width":"100"},');
                    v_r_body :=concat(v_r_body ,'","RACK_EQP_NO":"'||c_h_cnt.cnt_box_no);
                    v_r_body :=concat(v_r_body ,'","RACK_TERM_NO":"'||c_h_cnt.term_no);
                  elsif c_h_cnt.res_type_id = 703 then
                    v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"CNT_EQP_NO2","label":"光交设备2", "width":"200"},');
                    v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"CNT_TERM_NO2","label":"光交2端子", "width":"100"},');
                    v_r_body :=concat(v_r_body ,'","CNT_EQP_NO2":"'||c_h_cnt.cnt_box_no);
                    v_r_body :=concat(v_r_body ,'","CNT_TERM_NO2":"'||c_h_cnt.term_no);
                    
                    for c_h_term in C_GET_LINE_INFO_BYID(c_h_cnt.term_id) loop
                    for c_h_cnt3 in C_GET_ENT_SUPER_INFO_BYID(c_h_term.term_id) loop
                      if c_h_cnt3.res_type_id = 302 then
                        v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"RACK_EQP_NO","label":"ODF设备", "width":"200"},');
                        v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"RACK_TERM_NO","label":"ODF端子", "width":"100"},');
                        v_r_body :=concat(v_r_body ,'","RACK_EQP_NO":"'||c_h_cnt3.cnt_box_no);
                        v_r_body :=concat(v_r_body ,'","RACK_TERM_NO":"'||c_h_cnt3.term_no);
                      elsif c_h_cnt3.res_type_id = 703 then
                        v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"CNT_EQP_NO3","label":"光交设备3", "width":"200"},');
                        v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"CNT_TERM_NO3","label":"光交3端子", "width":"100"},');
                        v_r_body :=concat(v_r_body ,'","CNT_EQP_NO3":"'||c_h_cnt3.cnt_box_no);
                        v_r_body :=concat(v_r_body ,'","CNT_TERM_NO3":"'||c_h_cnt3.term_no);
                        for c_h_term4 in C_GET_LINE_INFO_BYID(c_h_cnt3.term_id) loop
                        for c_h_cnt4 in C_GET_ENT_SUPER_INFO_BYID(c_h_term4.term_id) loop
                          if c_h_cnt4.res_type_id = 302 then
                            v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"RACK_EQP_NO","label":"ODF设备", "width":"200"},');
                            v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"RACK_TERM_NO","label":"ODF端子", "width":"100"},');
                            v_r_body :=concat(v_r_body ,'","RACK_EQP_NO":"'||c_h_cnt4.cnt_box_no);
                            v_r_body :=concat(v_r_body ,'","RACK_TERM_NO":"'||c_h_cnt4.term_no);
                          elsif c_h_cnt4.res_type_id = 703 then
                            v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"CNT_EQP_NO4","label":"光交设备4", "width":"200"},');
                            v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"CNT_TERM_NO4","label":"光交4端子", "width":"100"},');
                            v_r_body :=concat(v_r_body ,'","CNT_EQP_NO4":"'||c_h_cnt4.cnt_box_no);
                            v_r_body :=concat(v_r_body ,'","CNT_TERM_NO4":"'||c_h_cnt4.term_no);
                            
                          end if;
                        end loop;  
                        end loop;
                      end if;
                    end loop;
                    end loop;
                    ---3
                  end if;
              end loop;
           end if;
           v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"PON_PORT","label":"PON口", "width":"200"},');
           v_r_body :=concat(v_r_body ,'","PON_PORT":"'||c_h_obd.pon);
           v_r_body :=concat(v_r_body ,'"},');
        end loop;
     else
          v_r_heard :=concat(v_r_heard ,'{"align":"center","key":"PORT_NO","label":"设备", "width":"200"},');
          v_r_body :=concat(v_r_body ,'{"PORT_NO":"'||sf_get_res_name(v_resId));
          v_r_body :=concat(v_r_body ,'"},');
     end if;
      v_r_heard := rtrim(v_r_heard ,',');
      v_r_body := rtrim(v_r_body ,',');
      v_r_heard := concat(v_r_heard ,']');
      v_r_body := concat(v_r_body ,']');
      v_return := '{';
      v_return := concat(v_return ,'"heard":');
      v_return := concat(v_return ,v_r_heard);
      v_return := concat(v_return ,',');
      v_return := concat(v_return ,'"body":');
      v_return := concat(v_return ,v_r_body);
      v_return := concat(v_return ,'}');
      
      --v_v200 :=  v_return;
    return v_return;
  end if;
  
  if intype = '1'  then
     v_return := '{"root":1,"nodes":[';
        for c_h_res in c_get_res_name_byId(v_resId) loop
          if c_h_res.resname is not null then
              v_return := concat(v_return ,'{"id":"s'||v_resId||'","value":"'||c_h_res.resname||'","type":"'||v_res_type_id||'"},');
          end if;
          v_has_cnt := v_has_cnt + 1;
         end loop;
    v_return := rtrim(v_return ,',');
    v_return := concat(v_return ,']}');
    return v_return;
  end if;
  
 if intype = '6' then
       v_return := '{"root":3,"nodes":[';
       if v_res_type_id in(2736,2530) then
        if v_res_type_id = 2736 then
          for c_h_ont in C_GET_ONT_SUPER_INFO_BYID(v_resId) loop
            v_return := concat(v_return ,'{"id":"s'||c_h_ont.eqp_id||'","value":"'||c_h_ont.eqp_no||'","type":"2736"},');
            if c_h_ont.jnt_box_id is not null then
              v_return := concat(v_return ,'{"id":"s'||c_h_ont.jnt_box_id||'","value":"'||c_h_ont.jnt_box_no||'","type":"704"},');
            end if;
            if c_h_ont.cnt_box_id is not null then
              v_return := concat(v_return ,'{"id":"s'||c_h_ont.cnt_box_id||'","value":"'||c_h_ont.cnt_box_no||'","type":"703"},');
            end if;
            if c_h_ont.obd_business_grade='25300302' then
              v_return := concat(v_return ,'{"id":"s'||c_h_ont.obd_id||'","value":"'||c_h_ont.obd_no||'","type":"2530"},');
              v_resId:=c_h_ont.parent_obd_id;
            else
              v_resId:=c_h_ont.obd_id;
            end if;
          end loop;
        end if;
           for c_h_obd in C_GET_OBD_SUPER_INFO_BYID(v_resId) loop
           v_return := concat(v_return ,'{"id":"s'||c_h_obd.obd_eqp_id||'","value":"'||c_h_obd.obd_eqp_no||'","type":"2530"},');
           if c_h_obd.term_id is not null then
              v_return := concat(v_return ,'{"id":"s'||c_h_obd.cnt_box_id||'","value":"'||c_h_obd.cnt_box_no||'","type":"703"},');
              for c_h_cnt in C_GET_ENT_SUPER_INFO_BYID(c_h_obd.term_id) loop
                  if c_h_cnt.res_type_id = 302 then
                    v_return := concat(v_return ,'{"id":"s'||c_h_cnt.cnt_box_id||'","value":"'||c_h_cnt.cnt_box_no||'","type":"'||c_h_cnt.res_type_id||'"},');
                  elsif c_h_cnt.res_type_id = 703 then
                    v_return := concat(v_return ,'{"id":"s'||c_h_cnt.cnt_box_id||'","value":"'||c_h_cnt.cnt_box_no||'","type":"'||c_h_cnt.res_type_id||'"},');
                    for c_h_term in C_GET_LINE_INFO_BYID(c_h_cnt.term_id) loop
                    for c_h_cnt3 in C_GET_ENT_SUPER_INFO_BYID(c_h_term.term_id) loop
                      if c_h_cnt3.res_type_id = 302 then
                        v_return := concat(v_return ,'{"id":"s'||c_h_cnt3.cnt_box_id||'","value":"'||c_h_cnt3.cnt_box_no||'","type":"'||c_h_cnt3.res_type_id||'"},');
                      elsif c_h_cnt3.res_type_id = 703 then
                        v_return := concat(v_return ,'{"id":"s'||c_h_cnt3.cnt_box_id||'","value":"'||c_h_cnt3.cnt_box_no||'","type":"'||c_h_cnt3.res_type_id||'"},');
                        for c_h_term4 in C_GET_LINE_INFO_BYID(c_h_cnt3.term_id) loop
                        for c_h_cnt4 in C_GET_ENT_SUPER_INFO_BYID(c_h_term4.term_id) loop
                          if c_h_cnt4.res_type_id = 302 then
                            v_return := concat(v_return ,'{"id":"s'||c_h_cnt4.cnt_box_id||'","value":"'||c_h_cnt4.cnt_box_no||'","type":"'||c_h_cnt4.res_type_id||'"},');
                          elsif c_h_cnt4.res_type_id = 703 then
                            v_return := concat(v_return ,'{"id":"s'||c_h_cnt4.cnt_box_id||'","value":"'||c_h_cnt4.cnt_box_no||'","type":"'||c_h_cnt4.res_type_id||'"},');
                          end if;
                        end loop;  
                        end loop;
                      end if;
                    end loop;
                    end loop;
                    ---3
                  end if;
              end loop;
           end if;
           v_return := concat(v_return ,'{"id":"s'||c_h_obd.olt_eqp_id||'","value":"'||c_h_obd.olt_eqp_no||'","type":"2510"},');
          
        end loop;
     end if;
     v_has_cnt := v_has_cnt + 1;    
     v_return := rtrim(v_return ,',');
     v_return := concat(v_return ,']}');
     return v_return;
  end if;
 
 if intype = '2'  then
  if v_res_type_id = 2510 then
    
     v_return := '{"root":0,"nodes":['; 
     --20180319 会议修改 2510 修改为不加载 odf 直接查询
       /*for c_h_odf in c_get_odf_by_eqpid(v_resId) loop
          if c_h_odf.rack_id is not null then
              v_return := concat(v_return ,'{"id":"s'||c_h_odf.rack_id||'","value":"'||c_h_odf.rack_name||'","type":"odf302"},');
          end if;
         v_has_cnt := v_has_cnt + 1;
       end loop;*/
       for c_h_obd in c_get_obd1_by_olteqpid(v_resId) loop
          if c_h_obd.eqp_id is not null then
              v_return := concat(v_return ,'{"id":"s'||c_h_obd.eqp_id||'","value":"'||c_h_obd.eqp_name||'","type":"2530"},');
          end if;
         v_has_cnt := v_has_cnt + 1;
       end loop;
       v_return := rtrim(v_return ,',');
       v_return := concat(v_return ,']}');
  elsif v_res_type_id = 302 then
      v_return := '{"root":0,"nodes":[';
       for c_h_cnt in c_get_cnt_by_eqpid(v_resId) loop
        if c_h_cnt.cnt_box_id is not null then
          v_return := concat(v_return ,'{"id":"s'||c_h_cnt.cnt_box_id||'","value":"'||c_h_cnt.cnt_box_name||'","type":"'||c_h_cnt.restype||'"},');
        end if;
        v_has_cnt := v_has_cnt + 1;
       end loop;
       v_return := rtrim(v_return ,',');
       v_return := concat(v_return ,']}');
  elsif v_res_type_id = 703 then
      v_return := '{"root":0,"nodes":[';
       for c_h_obd in c_get_obd_by_eqpid(v_resId) loop
        if c_h_obd.eqp_id is not null then
          v_return := concat(v_return ,'{"id":"s'||c_h_obd.eqp_id||'","value":"'||c_h_obd.eqp_name||'","type":"'||c_h_obd.restype||'"},');
        end if;
        v_has_cnt := v_has_cnt + 1;
       end loop;
       v_return := rtrim(v_return ,',');
       v_return := concat(v_return ,']}');
  elsif v_res_type_id = 704 then
     --根据光分查ONT
      v_return := '{"root":0,"nodes":[';
       for ch_jnt in c_get_ont_by_jntid(v_resId) loop
        if ch_jnt.eqp_id is not null then
          v_return := concat(v_return ,'{"id":"s'||ch_jnt.eqp_id||'","value":"'||ch_jnt.eqp_name||'","type":"'||ch_jnt.restype||'"},');
        end if;
        v_has_cnt := v_has_cnt + 1;
       end loop;
       v_return := rtrim(v_return ,',');
       v_return := concat(v_return ,']}');
  elsif v_res_type_id = 2530 then
     --根据OBD查询ONT、光分和二级OBD
      v_return := '{"root":0,"nodes":[';
       for c_h_ont1 in c_get_ont_by_eqpid1(v_resId) loop
        if c_h_ont1.z_eqp_id is not null then
          v_return := concat(v_return ,'{"id":"s'||c_h_ont1.z_eqp_id||'","value":"'||c_h_ont1.eqp_name||'","type":"'||c_h_ont1.restype||'"},');
        end if;
        v_has_cnt := v_has_cnt + 1;
       end loop;
       --二级OBD
       for c_h_obd in c_get_obd1_by_olteqpid(v_resId) loop
          if c_h_obd.eqp_id is not null then
              v_return := concat(v_return ,'{"id":"s'||c_h_obd.eqp_id||'","value":"'||c_h_obd.eqp_name||'","type":"2530"},');
          end if;
         v_has_cnt := v_has_cnt + 1;
       end loop;
       --分纤箱
       for c_h_jnt in c_get_jnt_by_eqpid(v_resId) loop
        if c_h_jnt.jnt_box_id is not null then
          v_return := concat(v_return ,'{"id":"s'||c_h_jnt.jnt_box_id||'","value":"'||c_h_jnt.jnt_box_name||'","type":"'||c_h_jnt.restype||'"},');
        end if;
        v_has_cnt := v_has_cnt + 1;
       end loop;
       v_return := rtrim(v_return ,',');
       v_return := concat(v_return ,']}');
   end if;
  end if;
   if v_has_cnt = 0 then
     return '';
   end if;
  return v_return;
EXCEPTION
  WHEN OTHERS THEN
    RETURN '';
END SF_GET_NODE_INFO_BY_ID;
/
