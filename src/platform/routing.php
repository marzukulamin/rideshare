<?php
declare(strict_types=1);
/** Fixed loopback service: no user-controlled upstream and no public routing API. */
function road_route(array $places,string $product,bool $instructions=false):array {
 $profile=$product==='bike'?'motorcycle':'car';
 $query='profile='.$profile.'&points_encoded=false&instructions='.($instructions?'true':'false').'&calc_points=true';
 foreach($places as $p)$query.='&point='.rawurlencode($p['lat'].','.$p['lng']);
 $c=curl_init('http://127.0.0.1:8989/route?'.$query);
 curl_setopt_array($c,[CURLOPT_RETURNTRANSFER=>true,CURLOPT_CONNECTTIMEOUT=>2,CURLOPT_TIMEOUT=>8,CURLOPT_FOLLOWLOCATION=>false,CURLOPT_PROTOCOLS=>CURLPROTO_HTTP]);
 $raw=curl_exec($c);$status=curl_getinfo($c,CURLINFO_RESPONSE_CODE);curl_close($c);
 if($raw===false||$status!==200)fail(503,'Road routing is unavailable. Your selections are kept; try again or contact Help.');
 $path=json_decode($raw,true)['paths'][0]??null;
 if(!$path||empty($path['points']['coordinates'])||!is_numeric($path['distance']))fail(503,'A usable road route could not be confirmed.');
 $snaps=$path['snapped_waypoints']['coordinates']??[];
 foreach($places as $i=>$p){$snap=$snaps[$i]??null;if(!$snap||distance_m($p['lat'],$p['lng'],(float)$snap[1],(float)$snap[0])>300)fail(422,'A selected point is too far from a routable road. Move the pin to a nearby accessible road.');}
 return ['distance_m'=>max(1,(int)round($path['distance'])),'duration_seconds'=>(int)round($path['time']/1000),'source'=>'gh11.1-'.$profile.'-osm20261009','instructions'=>$path['instructions']??[],'route'=>array_map(fn($p)=>['lng'=>(float)$p[0],'lat'=>(float)$p[1]],$path['points']['coordinates'])];
}
