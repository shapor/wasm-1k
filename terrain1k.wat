(module
  (import "" "s" (func $sin (param f64) (result f64)))
  (memory (export "m") 4)

  (func (export "r") (param $t f64)
    (local $col i32)
    (local $z f64)
    (local $sx f64)
    (local $wx f64)
    (local $wy f64)
    (local $h f64)
    (local $scrY i32)
    (local $maxY i32)    ;; highest filled row per column (draw bottom-up)
    (local $fog f64)
    (local $v f64)       ;; value for rainbow palette
    (local $off i32)

    ;; Clear to dark sky
    (local.set $off (i32.const 0))
    (loop $sky
      ;; row 0..255 -> gradient factor
      (local.set $v (f64.div
        (f64.convert_i32_u (i32.shr_u (local.get $off) (i32.const 10)))
        (f64.const 256.0)))
      ;; R=v*15, G=v*10, B=30+v*100 (deep blue gradient)
      (i32.store (local.get $off)
        (i32.or (i32.or (i32.or
          (i32.trunc_f64_s (f64.mul (local.get $v) (f64.const 15.0)))
          (i32.shl (i32.trunc_f64_s (f64.mul (local.get $v) (f64.const 10.0))) (i32.const 8)))
          (i32.shl (i32.trunc_f64_s (f64.add (f64.const 30.0)
            (f64.mul (local.get $v) (f64.const 100.0)))) (i32.const 16)))
          (i32.const 0xFF000000)))
      (br_if $sky (i32.lt_u
        (local.tee $off (i32.add (local.get $off) (i32.const 4)))
        (i32.const 262144)))
    )

    ;; Terrain raycasting
    (local.set $col (i32.const 0))
    (loop $cols
      (local.set $sx (f64.div
        (f64.convert_i32_s (i32.sub (local.get $col) (i32.const 128)))
        (f64.const 128.0)))
      (local.set $z (f64.const 0.5))
      (local.set $maxY (i32.const 256))

      (loop $march
        ;; World pos: camera sways and moves forward
        (local.set $wx (f64.add
          (f64.mul (local.get $sx) (local.get $z))
          (f64.mul (call $sin (f64.mul (local.get $t) (f64.const 0.13))) (f64.const 8.0))))
        (local.set $wy (f64.add (local.get $z)
          (f64.mul (local.get $t) (f64.const 2.0))))

        ;; Terrain: 3 octaves
        (local.set $h (f64.add (f64.add
          (f64.mul (call $sin (f64.add
            (f64.mul (local.get $wx) (f64.const 0.2))
            (f64.mul (local.get $wy) (f64.const 0.15))))
            (f64.const 4.0))
          (f64.mul (call $sin (f64.add
            (f64.mul (local.get $wx) (f64.const 0.5))
            (f64.mul (local.get $wy) (f64.const 0.4))))
            (f64.const 2.0)))
          (f64.mul (call $sin (f64.add
            (f64.mul (local.get $wx) (f64.const 1.1))
            (f64.mul (local.get $wy) (f64.const 0.9))))
            (f64.const 1.0))))

        ;; Project: scrY = 128 + (camera_h - h) * 40 / z
        (local.set $scrY (i32.trunc_f64_s (f64.add
          (f64.const 128.0)
          (f64.div
            (f64.mul (f64.sub (f64.const 3.0) (local.get $h)) (f64.const 40.0))
            (local.get $z)))))

        ;; Clamp scrY to valid range
        (if (i32.lt_s (local.get $scrY) (i32.const 0))
          (then (local.set $scrY (i32.const 0))))

        ;; Fill pixels from scrY to maxY if scrY < maxY
        (if (i32.lt_s (local.get $scrY) (local.get $maxY))
          (then
            ;; Fog: 1 - z/60, clamped
            (local.set $fog (f64.sub (f64.const 1.0)
              (f64.div (local.get $z) (f64.const 60.0))))
            (if (f64.lt (local.get $fog) (f64.const 0.05))
              (then (local.set $fog (f64.const 0.05))))

            ;; Rainbow color based on height + world position + time
            (local.set $v (f64.add (f64.add
              (f64.mul (local.get $h) (f64.const 0.5))
              (f64.mul (local.get $wx) (f64.const 0.05)))
              (f64.mul (local.get $t) (f64.const 0.3))))

            (loop $fill
              (local.set $maxY (i32.sub (local.get $maxY) (i32.const 1)))
              (i32.store
                (i32.add (i32.shl (local.get $col) (i32.const 2))
                         (i32.shl (local.get $maxY) (i32.const 10)))
                (i32.or (i32.or (i32.or
                  ;; R
                  (i32.trunc_f64_s (f64.mul (f64.add
                    (f64.mul (call $sin (local.get $v)) (f64.const 127.0))
                    (f64.const 128.0)) (local.get $fog)))
                  ;; G
                  (i32.shl (i32.trunc_f64_s (f64.mul (f64.add
                    (f64.mul (call $sin (f64.add (local.get $v) (f64.const 2.094))) (f64.const 127.0))
                    (f64.const 128.0)) (local.get $fog))) (i32.const 8)))
                  ;; B
                  (i32.shl (i32.trunc_f64_s (f64.mul (f64.add
                    (f64.mul (call $sin (f64.add (local.get $v) (f64.const 4.189))) (f64.const 127.0))
                    (f64.const 128.0)) (local.get $fog))) (i32.const 16)))
                  (i32.const 0xFF000000)))
              (br_if $fill (i32.gt_s (local.get $maxY) (local.get $scrY)))
            )
          )
        )

        ;; Step deeper: accelerating for LOD
        (local.set $z (f64.add (local.get $z)
          (f64.add (f64.const 0.3) (f64.mul (local.get $z) (f64.const 0.03)))))

        (br_if $march (i32.and
          (f64.lt (local.get $z) (f64.const 60.0))
          (i32.gt_s (local.get $maxY) (i32.const 0))))
      )

      (br_if $cols (i32.lt_u
        (local.tee $col (i32.add (local.get $col) (i32.const 1)))
        (i32.const 256)))
    )
  )
)
